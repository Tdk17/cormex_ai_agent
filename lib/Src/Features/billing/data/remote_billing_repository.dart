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
    final currentResult = await _httpManager.cloudFunction(
      name: Endpoints.billingCurrent,
      parameters: <String, dynamic>{'workspaceId': workspaceId},
    );
    final current = switch (currentResult) {
      ApiSuccess<Map<String, dynamic>>(:final data) => BillingOverviewModel.fromJson(data),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };

    final usageResult = await _httpManager.cloudFunction(
      name: Endpoints.usageCurrent,
      parameters: <String, dynamic>{'workspaceId': workspaceId},
    );
    return switch (usageResult) {
      ApiSuccess<Map<String, dynamic>>(:final data) => current.copyWith(
          usage: BillingUsageModel.fromJson(<String, dynamic>{
            ..._map(data['usage']),
            'period': data['period'],
          }),
        ),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }

  @override
  Future<BillingCatalogModel> getPlans({required String workspaceId}) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.billingPlans,
      parameters: <String, dynamic>{'workspaceId': workspaceId},
    );
    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data) => BillingCatalogModel.fromJson(data),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }

  @override
  Future<BillingCheckoutModel> checkout({
    required String workspaceId,
    required String planCode,
    required String returnUrl,
  }) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.billingCheckout,
      parameters: <String, dynamic>{
        'workspaceId': workspaceId,
        'planCode': planCode,
        'returnUrl': _billingReturnUrl(returnUrl),
      },
    );
    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data) => BillingCheckoutModel.fromJson(data),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }

  @override
  Future<BillingOverviewModel> cancel({required String workspaceId}) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.billingCancel,
      parameters: <String, dynamic>{'workspaceId': workspaceId},
    );
    switch (result) {
      case ApiFailure<Map<String, dynamic>>(:final error):
        throw error;
      case ApiSuccess<Map<String, dynamic>>() :
        return getCurrent(workspaceId: workspaceId);
    }
  }

  static Map<String, dynamic> _map(dynamic raw) =>
      raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

  static String _billingReturnUrl(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'https://cormexcrm.com.br/settings/billing';
    }
    return uri.replace(path: '/settings/billing', query: null, fragment: null).toString();
  }
}
