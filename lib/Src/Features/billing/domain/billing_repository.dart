import 'package:agente_vendas_saas/Src/Features/billing/domain/billing_models.dart';

abstract interface class BillingRepository {
  Future<BillingOverviewModel> getCurrent({required String workspaceId});

  Future<BillingCatalogModel> getPlans({required String workspaceId});

  Future<BillingCheckoutModel> checkout({
    required String workspaceId,
    required String planCode,
    required String returnUrl,
  });

  Future<BillingOverviewModel> cancel({required String workspaceId});
}
