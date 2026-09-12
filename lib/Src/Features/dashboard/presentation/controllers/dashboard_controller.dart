import 'dart:async';

import 'package:agente_vendas_saas/Src/Core/api/api_exception.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:agente_vendas_saas/Src/Features/dashboard/domain/dashboard_repository.dart';
import 'package:agente_vendas_saas/Src/Shared/models/dashboard_metrics_model.dart';
import 'package:signals/signals.dart';

class DashboardController {
  DashboardController(this._repository, this._authController) {
    _disposeWorkspaceEffect = effect(() {
      final workspaceId = _workspaceId;
      if (_observedWorkspaceId == workspaceId) return;
      _observedWorkspaceId = workspaceId;
      batch(() {
        metrics.value = null;
        errorMessage.value = null;
        correlationId.value = null;
        state.value = ScreenState.initial;
      });
      if (workspaceId != null) unawaited(load(force: true));
    });
  }

  final DashboardRepository _repository;
  final AuthController _authController;
  String? _observedWorkspaceId;
  late final void Function() _disposeWorkspaceEffect;

  final Signal<ScreenState> state = signal(ScreenState.initial);
  final Signal<DashboardMetricsModel?> metrics = signal<DashboardMetricsModel?>(null);
  final Signal<String> period = signal('30d');
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
      final data = await _repository.getMetrics(
        workspaceId: workspaceId,
        period: period.value,
      );
      if (_workspaceId != workspaceId) return;
      batch(() {
        metrics.value = data;
        state.value = data.isEmpty ? ScreenState.empty : ScreenState.success;
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
        errorMessage.value = 'Não foi possível carregar os indicadores.';
        state.value = ScreenState.error;
      });
    }
  }

  Future<void> changePeriod(String value) async {
    if (period.value == value) return;
    period.value = value;
    await load(force: true);
  }

  String? get _workspaceId =>
      _authController.session.value?.selectedWorkspace?.id;

  void dispose() => _disposeWorkspaceEffect();
}
