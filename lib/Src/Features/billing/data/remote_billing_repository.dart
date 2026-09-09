import 'package:agente_vendas_saas/Src/Core/api/api_result.dart';
import 'package:agente_vendas_saas/Src/Core/http/endpoints.dart';
import 'package:agente_vendas_saas/Src/Core/http/http_manager.dart';
import 'package:agente_vendas_saas/Src/Features/billing/domain/billing_models.dart';
import 'package:agente_vendas_saas/Src/Features/billing/domain/billing_repository.dart';

class RemoteBillingRepository implements BillingRepository {
  RemoteBillingRepository(this._httpManager);

  final HttpManager _httpManager;

  @override
  Future<BillingOverviewModel> getCurrent({required String workspaceId}) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.usageCurrent,
      parameters: <String, dynamic>{'workspaceId': workspaceId},
    );

    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data) =>
        BillingOverviewModel.fromJson(data),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }

  @override
  Future<BillingCatalogModel> listPlans({required String workspaceId}) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.billingPlansList,
      parameters: <String, dynamic>{'workspaceId': workspaceId},
    );

    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data) =>
        BillingCatalogModel.fromJson(data),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }

  @override
  Future<BillingCheckoutModel> createCheckout({
    required String workspaceId,
    required String planId,
    required BillingCycle billingCycle,
    required BillingPaymentMethod paymentMethod,
  }) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.billingCheckoutCreate,
      parameters: <String, dynamic>{
        'workspaceId': workspaceId,
        'planId': planId,
        'billingCycle': billingCycle.apiValue,
        'paymentMethod': paymentMethod.apiValue,
      },
    );

    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data) =>
        BillingCheckoutModel.fromJson(data),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }

  @override
  Future<BillingCheckoutModel> getCheckoutStatus({
    required String workspaceId,
    required String checkoutId,
  }) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.billingCheckoutStatus,
      parameters: <String, dynamic>{
        'workspaceId': workspaceId,
        'checkoutId': checkoutId,
      },
    );

    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data) =>
        BillingCheckoutModel.fromJson(data),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }
}
