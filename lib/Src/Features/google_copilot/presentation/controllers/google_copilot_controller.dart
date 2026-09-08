import 'dart:async';

import 'package:agente_vendas_saas/Src/Core/api/api_exception.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:agente_vendas_saas/Src/Features/google_copilot/domain/google_copilot_models.dart';
import 'package:agente_vendas_saas/Src/Features/google_copilot/domain/google_copilot_repository.dart';
import 'package:signals/signals.dart';

class GoogleCopilotController {
  GoogleCopilotController(this._repository, this._authController) {
    _disposeWorkspaceEffect = effect(() {
      final workspaceId = _workspaceId;
      if (_observedWorkspaceId == workspaceId) return;
      _observedWorkspaceId = workspaceId;
      batch(() {
        state.value = ScreenState.initial;
        connection.value = null;
        kpis.value = null;
        errorMessage.value = null;
        successMessage.value = null;
      });
      if (workspaceId != null) unawaited(load());
    });
  }

  final GoogleCopilotRepository _repository;
  final AuthController _authController;
  String? _observedWorkspaceId;
  late final void Function() _disposeWorkspaceEffect;

  final Signal<ScreenState> state = signal(ScreenState.initial);
  final Signal<GoogleCopilotConnection?> connection = signal(null);
  final Signal<GoogleCopilotKpis?> kpis = signal(null);
  final Signal<bool> busy = signal(false);
  final Signal<String?> errorMessage = signal(null);
  final Signal<String?> successMessage = signal(null);

  Future<void> load() async {
    final workspaceId = _workspaceId;
    if (workspaceId == null) return;
    batch(() {
      state.value = ScreenState.loading;
      errorMessage.value = null;
    });
    try {
      final result = await _repository.connection(workspaceId: workspaceId);
      batch(() {
        connection.value = result;
        state.value = ScreenState.success;
      });
      if (result.connected) {
        await loadDashboard();
      }
    } on ApiException catch (error) {
      _setError(error.userMessage);
    } on Object {
      _setError('Não foi possível carregar o Google Copilot.');
    }
  }

  Future<Uri?> startOAuth(String returnUrl) async {
    final workspaceId = _workspaceId;
    if (workspaceId == null || busy.value) return null;
    busy.value = true;
    errorMessage.value = null;
    try {
      return await _repository.startOAuth(
        workspaceId: workspaceId,
        returnUrl: returnUrl,
      );
    } on ApiException catch (error) {
      _setError(error.userMessage);
      return null;
    } on Object {
      _setError('Não foi possível iniciar a conexão com o Google.');
      return null;
    } finally {
      busy.value = false;
    }
  }

  Future<bool> saveProperties({
    required String googleAdsCustomerId,
    required String ga4PropertyId,
    required String searchConsoleSiteUrl,
  }) async {
    final workspaceId = _workspaceId;
    if (workspaceId == null || busy.value) return false;
    busy.value = true;
    errorMessage.value = null;
    successMessage.value = null;
    try {
      await _repository.saveProperties(
        workspaceId: workspaceId,
        googleAdsCustomerId: googleAdsCustomerId,
        ga4PropertyId: ga4PropertyId,
        searchConsoleSiteUrl: searchConsoleSiteUrl,
      );
      successMessage.value = 'Propriedades Google salvas.';
      await load();
      return true;
    } on ApiException catch (error) {
      _setError(error.userMessage);
      return false;
    } on Object {
      _setError('Não foi possível salvar as propriedades Google.');
      return false;
    } finally {
      busy.value = false;
    }
  }

  Future<void> loadDashboard() async {
    final workspaceId = _workspaceId;
    if (workspaceId == null || connection.value?.connected != true) return;
    try {
      final now = DateTime.now();
      final result = await _repository.dashboard(
        workspaceId: workspaceId,
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now,
      );
      kpis.value = result;
    } on ApiException catch (error) {
      errorMessage.value = error.userMessage;
    } on Object {
      errorMessage.value = 'Não foi possível carregar os indicadores Google.';
    }
  }

  Future<bool> savePolicy({
    required double maxDailyBudget,
    required double maxBudgetChangePercent,
    required bool allowAutoPause,
    required bool allowAutoBudgetChange,
  }) async {
    final workspaceId = _workspaceId;
    if (workspaceId == null || busy.value) return false;
    if (maxDailyBudget < 0 || maxBudgetChangePercent < 0) {
      _setError('Os limites não podem ser negativos.');
      return false;
    }
    busy.value = true;
    errorMessage.value = null;
    try {
      final micros = (maxDailyBudget * 1000000).round().toString();
      await _repository.savePolicy(
        workspaceId: workspaceId,
        policy: GoogleCopilotPolicy(
          maxDailyBudgetMicros: micros,
          maxBudgetChangePercent: maxBudgetChangePercent,
          allowAutoPause: allowAutoPause,
          allowAutoBudgetChange: allowAutoBudgetChange,
        ),
      );
      successMessage.value = 'Política de autonomia atualizada.';
      return true;
    } on ApiException catch (error) {
      _setError(error.userMessage);
      return false;
    } on Object {
      _setError('Não foi possível salvar a política de autonomia.');
      return false;
    } finally {
      busy.value = false;
    }
  }

  String? get _workspaceId =>
      _authController.session.value?.selectedWorkspace?.id;

  void clearFeedback() {
    errorMessage.value = null;
    successMessage.value = null;
  }

  void dispose() => _disposeWorkspaceEffect();

  void _setError(String message) {
    batch(() {
      errorMessage.value = message;
      state.value = ScreenState.error;
    });
  }
}
