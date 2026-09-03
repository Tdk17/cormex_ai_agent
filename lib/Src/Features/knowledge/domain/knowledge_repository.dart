import 'package:agente_vendas_saas/Src/Features/knowledge/domain/knowledge_models.dart';

abstract interface class KnowledgeRepository {
  Future<KnowledgePageResult> list({
    required String workspaceId,
    String? search,
    String? type,
    String? status,
    String? cursor,
    int limit = 30,
  });

  Future<KnowledgeSourceModel> create({
    required String workspaceId,
    required KnowledgeSourceInput input,
    required String clientRequestId,
  });

  Future<KnowledgeSourceModel> uploadFile({
    required String workspaceId,
    required KnowledgeFileInput input,
    required String clientRequestId,
    void Function(int sent, int total)? onSendProgress,
  });

  Future<void> delete({
    required String workspaceId,
    required String sourceId,
  });
}
