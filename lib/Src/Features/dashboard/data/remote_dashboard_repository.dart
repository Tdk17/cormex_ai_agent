import 'package:agente_vendas_saas/Src/Core/api/api_result.dart';
import 'package:agente_vendas_saas/Src/Core/http/endpoints.dart';
import 'package:agente_vendas_saas/Src/Core/http/http_manager.dart';
import 'package:agente_vendas_saas/Src/Features/dashboard/domain/dashboard_repository.dart';
import 'package:agente_vendas_saas/Src/Shared/models/dashboard_metrics_model.dart';

class RemoteDashboardRepository implements DashboardRepository {
  RemoteDashboardRepository(this._httpManager);

  final HttpManager _httpManager;

  @override
  Future<DashboardMetricsModel> getMetrics({
    required String workspaceId,
    required String period,
  }) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.dashboardMetrics,
      parameters: <String, dynamic>{
        'workspaceId': workspaceId,
        'period': period,
      },
    );
    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data) =>
        DashboardMetricsModel.fromJson(data),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }
}
