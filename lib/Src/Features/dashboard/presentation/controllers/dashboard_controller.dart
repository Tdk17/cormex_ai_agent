import 'package:agente_vendas_saas/Src/Core/api/api_exception.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:agente_vendas_saas/Src/Features/dashboard/domain/dashboard_repository.dart';
import 'package:agente_vendas_saas/Src/Shared/models/dashboard_metrics_model.dart';
import 'package:signals/signals.dart';

class DashboardController {
  DashboardController(this._repository, this._authController);

  final DashboardRepository _repository;
  final AuthController _authController;

  final Signal<ScreenState> state = signal(ScreenState.initial);
  final Signal<DashboardMetricsModel?> metrics = signal<DashboardMetricsModel?>(null);
  final Signal<String> period = signal('30d');
  final Signal<String?> errorMessage = signal<String?>(null);
  final Signal<String?> correlationId = signal<String?>(null);

  Future<void> load({bool force = false}) async {
    if (!force && state.value == ScreenState.loading) return;
    final workspaceId = _authController.session.value?.selectedWorkspace?.id;
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
      batch(() {
        metrics.value = data;
        state.value = data.totalLeads == 0 ? ScreenState.empty : ScreenState.success;
      });
    } on ApiException catch (error) {
      batch(() {
        errorMessage.value = error.userMessage;
        correlationId.value = error.correlationId;
        state.value = ScreenState.error;
      });
    } on Object {
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
}
