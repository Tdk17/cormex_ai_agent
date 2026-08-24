import 'package:agente_vendas_saas/Src/Shared/models/dashboard_metrics_model.dart';

abstract interface class DashboardRepository {
  Future<DashboardMetricsModel> getMetrics({
    required String workspaceId,
    required String period,
  });
}
