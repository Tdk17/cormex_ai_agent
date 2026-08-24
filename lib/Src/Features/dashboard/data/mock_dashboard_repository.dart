import 'package:agente_vendas_saas/Src/Features/dashboard/domain/dashboard_repository.dart';
import 'package:agente_vendas_saas/Src/Shared/models/dashboard_metrics_model.dart';

class MockDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardMetricsModel> getMetrics({
    required String workspaceId,
    required String period,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 750));
    return const DashboardMetricsModel(
      totalLeads: 2847,
      activeConversations: 186,
      qualifiedLeads: 392,
      openOpportunities: 147,
      conversions: 63,
      conversionRate: 18.7,
      funnel: <String, int>{
        'Novos leads': 640,
        'Em conversa': 388,
        'Qualificados': 214,
        'Proposta': 126,
        'Convertidos': 63,
      },
    );
  }
}
