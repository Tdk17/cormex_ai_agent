import 'dart:async';

import 'package:agente_vendas_saas/Src/Core/api/api_exception.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:agente_vendas_saas/Src/Features/integrations/domain/integration_models.dart';
import 'package:agente_vendas_saas/Src/Features/integrations/domain/integrations_repository.dart';
import 'package:signals/signals.dart';

class IntegrationsController {
  IntegrationsController(this._repository, this._authController) {
    _disposeWorkspaceEffect = effect(() {
      final workspaceId = _workspaceId;
      if (_observedWorkspaceId == workspaceId) return;
      _observedWorkspaceId = workspaceId;
      batch(() {
        items.value = const <IntegrationModel>[];
        state.value = ScreenState.initial;
        errorMessage.value = null;
        successMessage.value = null;
        correlationId.value = null;
      });
      if (workspaceId != null) unawaited(load(force: true));
    });
  }

  final IntegrationsRepository _repository;
  final AuthController _authController;
  String? _observedWorkspaceId;
  late final void Function() _disposeWorkspaceEffect;

  final Signal<ScreenState> state = signal(ScreenState.initial);
  final Signal<List<IntegrationModel>> items =
      signal<List<IntegrationModel>>(const <IntegrationModel>[]);
  final Signal<String?> busyProvider = signal<String?>(null);
  final Signal<String?> errorMessage = signal<String?>(null);
  final Signal<String?> successMessage = signal<String?>(null);
  final Signal<String?> correlationId = signal<String?>(null);

  IntegrationModel? provider(String provider) {
    for (final item in items.value) {
      if (item.provider == provider) return item;
    }
    return null;
  }

  Future<void> load({bool force = false}) async {
    if (!force && state.value == ScreenState.loading) return;
    final workspaceId = _workspaceId;
    if (workspaceId == null) {
      state.value = ScreenState.empty;
      return;
    }

    batch(() {
      state.value = ScreenState.loading;
      errorMessage.value = null;
      successMessage.value = null;
      correlationId.value = null;
    });

    try {
      final result = await _repository.list(workspaceId: workspaceId);
      batch(() {
        items.value = result.items;
        correlationId.value = result.correlationId;
        state.value =
            result.items.isEmpty ? ScreenState.empty : ScreenState.success;
      });
    } on ApiException catch (error) {
      _setError(error.userMessage, error.correlationId);
    } on Object {
      _setError('Não foi possível consultar as integrações.', null);
    }
  }

  Future<Uri?> startAuthorization({
    required String provider,
    required String returnUrl,
  }) async {
    if (busyProvider.value != null) return null;
    final workspaceId = _workspaceId;
    if (workspaceId == null) return null;

    batch(() {
      busyProvider.value = provider;
      errorMessage.value = null;
      successMessage.value = null;
      correlationId.value = null;
    });

    try {
      final current = this.provider(provider);
      final isDisconnected = current == null ||
          current.status == IntegrationStatuses.disconnected ||
          current.status == IntegrationStatuses.expired ||
          current.status == IntegrationStatuses.authorizationError;
      final isWhatsApp = provider == IntegrationProviders.whatsapp;

      // WhatsApp uses an isolated QR/Web session per workspace. The backend
      // owns the session and returns only a short-lived URL where the QR is
      // displayed. No WhatsApp/Meta password or browser session is stored in
      // the Flutter client.
      final action = isWhatsApp
          ? (isDisconnected ? 'start_qr' : 'refresh_qr')
          : (isDisconnected ? 'start' : 'refresh');

      final result = await _repository.connect(
        workspaceId: workspaceId,
        provider: provider,
        action: action,
        returnUrl: returnUrl,
        clientRequestId:
            'integration_${provider}_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (result.integration != null) _upsert(result.integration!);
      correlationId.value = result.correlationId;

      final authorizationUrl = result.authorizationUrl;
      if (authorizationUrl == null) {
        if (result.integration?.connected == true || result.status == 'connected') {
          successMessage.value = 'Integração conectada com sucesso.';
          await load(force: true);
          return null;
        }
        errorMessage.value = isWhatsApp
            ? 'O backend não retornou a URL temporária do QR Code do WhatsApp.'
            : 'O backend não retornou a URL de autorização do provedor.';
        return null;
      }

      final uri = Uri.tryParse(authorizationUrl);
      if (uri == null || !uri.hasScheme) {
        errorMessage.value = isWhatsApp
            ? 'A URL do QR Code retornada pelo backend é inválida.'
            : 'A URL de autorização retornada é inválida.';
        return null;
      }
      successMessage.value = isWhatsApp
          ? 'Escaneie o QR Code com o WhatsApp do cliente para concluir a conexão.'
          : 'Conclua a autorização na página do provedor.';
      return uri;
    } on ApiException catch (error) {
      _setError(error.userMessage, error.correlationId);
      return null;
    } on Object {
      _setError('Não foi possível iniciar a conexão com o canal.', null);
      return null;
    } finally {
      busyProvider.value = null;
    }
  }

  Future<bool> disconnect(IntegrationModel integration) async {
    if (busyProvider.value != null) return false;
    final workspaceId = _workspaceId;
    if (workspaceId == null || integration.id.isEmpty) return false;

    batch(() {
      busyProvider.value = integration.provider;
      errorMessage.value = null;
      successMessage.value = null;
      correlationId.value = null;
    });

    try {
      final result = await _repository.connect(
        workspaceId: workspaceId,
        provider: integration.provider,
        action: 'disconnect',
        integrationId: integration.id,
        expectedVersion: integration.version,
        clientRequestId:
            'integration_disconnect_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (result.integration != null) _upsert(result.integration!);
      correlationId.value = result.correlationId;
      successMessage.value = 'Integração desconectada.';
      await load(force: true);
      return true;
    } on ApiException catch (error) {
      _setError(error.userMessage, error.correlationId);
      return false;
    } on Object {
      _setError('Não foi possível desconectar a integração.', null);
      return false;
    } finally {
      busyProvider.value = null;
    }
  }

  void clearFeedback() {
    batch(() {
      errorMessage.value = null;
      successMessage.value = null;
      correlationId.value = null;
    });
  }

  void dispose() => _disposeWorkspaceEffect();

  void _upsert(IntegrationModel integration) {
    final next = <IntegrationModel>[...items.value];
    final index = next.indexWhere(
      (IntegrationModel item) =>
          item.id == integration.id || item.provider == integration.provider,
    );
    if (index >= 0) {
      next[index] = integration;
    } else {
      next.add(integration);
    }
    items.value = next;
    state.value = ScreenState.success;
  }

  String? get _workspaceId =>
      _authController.session.value?.selectedWorkspace?.id;

  void _setError(String message, String? requestCorrelationId) {
    batch(() {
      errorMessage.value = message;
      correlationId.value = requestCorrelationId;
      state.value = ScreenState.error;
    });
  }
}
