import 'package:agente_vendas_saas/Src/Features/billing/domain/billing_models.dart';

abstract interface class BillingRepository {
  Future<BillingOverviewModel> getCurrent({required String workspaceId});

  Future<BillingCatalogModel> listPlans({required String workspaceId});

  Future<BillingCheckoutModel> createCheckout({
    required String workspaceId,
    required String planId,
    required BillingCycle billingCycle,
    required BillingPaymentMethod paymentMethod,
  });

  Future<BillingCheckoutModel> getCheckoutStatus({
    required String workspaceId,
    required String checkoutId,
  });
}
