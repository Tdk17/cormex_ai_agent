import 'package:agente_vendas_saas/Src/Features/integrations/domain/integration_models.dart';

abstract interface class IntegrationsRepository {
  Future<IntegrationListResult> list({
    required String workspaceId,
    String? type,
  });

  Future<IntegrationCommandResult> connect({
    required String workspaceId,
    required String provider,
    required String action,
    required String clientRequestId,
    String? returnUrl,
    String? integrationId,
    int? expectedVersion,
  });
}
