import 'dart:async';

import 'package:agente_vendas_saas/Src/Core/api/api_exception.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:agente_vendas_saas/Src/Features/billing/domain/billing_models.dart';
import 'package:agente_vendas_saas/Src/Features/billing/domain/billing_repository.dart';
import 'package:signals/signals.dart';

class BillingController {
  BillingController(this._repository, this._authController) {
    _disposeWorkspaceEffect = effect(() {
      final workspaceId = _workspaceId;
      if (_observedWorkspaceId == workspaceId) return;
      _observedWorkspaceId = workspaceId;
      batch(() {
        overview.value = null;
        errorMessage.value = null;
        correlationId.value = null;
        state.value = ScreenState.initial;
      });
      if (workspaceId != null) unawaited(load(force: true));
    });
  }

  final BillingRepository _repository;
  final AuthController _authController;
  String? _observedWorkspaceId;
  late final void Function() _disposeWorkspaceEffect;

  final Signal<ScreenState> state = signal(ScreenState.initial);
  final Signal<BillingOverviewModel?> overview =
      signal<BillingOverviewModel?>(null);
  final Signal<String?> errorMessage = signal<String?>(null);
  final Signal<String?> correlationId = signal<String?>(null);

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
      correlationId.value = null;
    });

    try {
      final data = await _repository.getCurrent(workspaceId: workspaceId);
      if (_workspaceId != workspaceId) return;
      batch(() {
        overview.value = data;
        state.value = ScreenState.success;
      });
    } on ApiException catch (error) {
      if (_workspaceId != workspaceId) return;
      batch(() {
        errorMessage.value = error.userMessage;
        correlationId.value = error.correlationId;
        state.value = ScreenState.error;
      });
    } on Object {
      if (_workspaceId != workspaceId) return;
      batch(() {
        errorMessage.value = 'Não foi possível carregar o plano e o consumo.';
        state.value = ScreenState.error;
      });
    }
  }

  String? get _workspaceId =>
      _authController.session.value?.selectedWorkspace?.id;

  void dispose() => _disposeWorkspaceEffect();
}
