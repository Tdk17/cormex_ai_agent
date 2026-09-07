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
}
