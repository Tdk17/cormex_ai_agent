import 'package:agente_vendas_saas/Src/Features/billing/domain/billing_models.dart';

abstract interface class BillingRepository {
  Future<BillingOverviewModel> getCurrent({required String workspaceId});
}
