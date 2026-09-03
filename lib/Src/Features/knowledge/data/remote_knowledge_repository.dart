import 'package:agente_vendas_saas/Src/Core/api/api_exception.dart';
import 'package:agente_vendas_saas/Src/Core/api/api_result.dart';
import 'package:agente_vendas_saas/Src/Core/http/endpoints.dart';
import 'package:agente_vendas_saas/Src/Core/http/http_manager.dart';
import 'package:agente_vendas_saas/Src/Features/knowledge/domain/knowledge_models.dart';
import 'package:agente_vendas_saas/Src/Features/knowledge/domain/knowledge_repository.dart';

class RemoteKnowledgeRepository implements KnowledgeRepository {
  RemoteKnowledgeRepository(this._httpManager);

  final HttpManager _httpManager;

  @override
  Future<KnowledgePageResult> list({
    required String workspaceId,
    String? search,
    String? type,
    String? status,
    String? cursor,
    int limit = 30,
  }) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.knowledgeList,
      parameters: <String, dynamic>{
        'workspaceId': workspaceId,
        if (search?.trim().isNotEmpty == true) 'search': search!.trim(),
        if (type != null) 'type': type,
        if (status != null) 'status': status,
        if (cursor != null) 'cursor': cursor,
        'limit': limit,
      },
    );
    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data, :final meta) =>
        KnowledgePageResult(
          items: _maps(data['items'] ?? data['sources'])
              .map(KnowledgeSourceModel.fromJson)
              .toList(growable: false),
          nextCursor: meta.nextCursor ?? data['nextCursor']?.toString(),
          correlationId: meta.correlationId,
        ),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }

  @override
  Future<KnowledgeSourceModel> create({
    required String workspaceId,
    required KnowledgeSourceInput input,
    required String clientRequestId,
  }) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.knowledgeCreate,
      parameters: <String, dynamic>{
        'workspaceId': workspaceId,
        'source': input.toJson(),
        'clientRequestId': clientRequestId,
      },
    );
    return _source(result);
  }

  @override
  Future<KnowledgeSourceModel> uploadFile({
    required String workspaceId,
    required KnowledgeFileInput input,
    required String clientRequestId,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final upload = await _httpManager.uploadParseFile(
      fileName: 'knowledge-$workspaceId-${input.fileName}',
      bytes: input.bytes,
      contentType: input.mimeType,
      onSendProgress: onSendProgress,
    );
    final fileUrl = switch (upload) {
      ApiSuccess<Map<String, dynamic>>(:final data) => data['url']?.toString(),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
    if (fileUrl == null || fileUrl.trim().isEmpty) {
      throw const ApiException(
        code: 'FILE_UPLOAD_ERROR',
        message: 'O armazenamento não retornou a URL do arquivo.',
      );
    }
    return create(
      workspaceId: workspaceId,
      clientRequestId: clientRequestId,
      input: KnowledgeSourceInput(
        type: 'file',
        name: input.name,
        fileName: input.fileName,
        mimeType: input.mimeType,
        fileUrl: fileUrl,
      ),
    );
  }

  @override
  Future<void> delete({
    required String workspaceId,
    required String sourceId,
  }) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.knowledgeDelete,
      parameters: <String, dynamic>{
        'workspaceId': workspaceId,
        'sourceId': sourceId,
      },
    );
    switch (result) {
      case ApiSuccess<Map<String, dynamic>>():
        return;
      case ApiFailure<Map<String, dynamic>>(:final error):
        throw error;
    }
  }

  static KnowledgeSourceModel _source(
    ApiResult<Map<String, dynamic>> result,
  ) {
    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data) =>
        KnowledgeSourceModel.fromJson(_map(data['source'] ?? data)),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }

  static Map<String, dynamic> _map(dynamic raw) => raw is Map
      ? Map<String, dynamic>.from(raw)
      : const <String, dynamic>{};

  static Iterable<Map<String, dynamic>> _maps(dynamic raw) {
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw.whereType<Map>().map(Map<String, dynamic>.from);
  }
}
