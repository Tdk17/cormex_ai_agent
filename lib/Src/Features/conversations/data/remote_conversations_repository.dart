import 'package:agente_vendas_saas/Src/Core/api/api_exception.dart';
import 'package:agente_vendas_saas/Src/Core/api/api_result.dart';
import 'package:agente_vendas_saas/Src/Core/http/endpoints.dart';
import 'package:agente_vendas_saas/Src/Core/http/http_manager.dart';
import 'package:agente_vendas_saas/Src/Features/conversations/domain/conversation_filters.dart';
import 'package:agente_vendas_saas/Src/Features/conversations/domain/conversation_page.dart';
import 'package:agente_vendas_saas/Src/Features/conversations/domain/conversation_thread.dart';
import 'package:agente_vendas_saas/Src/Features/conversations/domain/conversations_repository.dart';
import 'package:agente_vendas_saas/Src/Shared/models/conversation_models.dart';
import 'package:agente_vendas_saas/Src/Shared/models/lead_model.dart';

class RemoteConversationsRepository implements ConversationsRepository {
  RemoteConversationsRepository(this._httpManager);

  final HttpManager _httpManager;

  @override
  Future<ConversationPage> list({
    required String workspaceId,
    required ConversationFilters filters,
    String? cursor,
    int limit = 30,
  }) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.conversationsList,
      parameters: <String, dynamic>{
        'workspaceId': workspaceId,
        ...filters.toParameters(),
        if (cursor != null) 'cursor': cursor,
        'limit': limit,
      },
    );
    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data, :final meta) =>
        ConversationPage(
          items: _maps(data['items'] ?? data['conversations'])
              .map(ConversationModel.fromJson)
              .toList(growable: false),
          owners: _maps(data['owners'])
              .map(ConversationOwnerModel.fromJson)
              .where(
                (ConversationOwnerModel item) =>
                    item.id.isNotEmpty && item.name.isNotEmpty,
              )
              .toList(growable: false),
          nextCursor: meta.nextCursor ?? data['nextCursor']?.toString(),
          correlationId: meta.correlationId,
        ),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }

  @override
  Future<ConversationThread> get({
    required String workspaceId,
    required String conversationId,
    String? messagesCursor,
    int messagesLimit = 50,
  }) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.conversationsGet,
      parameters: <String, dynamic>{
        'workspaceId': workspaceId,
        'conversationId': conversationId,
        if (messagesCursor != null) 'messagesCursor': messagesCursor,
        'messagesLimit': messagesLimit,
        'markAsRead': messagesCursor == null,
      },
    );
    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data, :final meta) =>
        _thread(data, meta),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }

  @override
  Future<SendMessageResult> sendMessage({
    required String workspaceId,
    required String conversationId,
    required String content,
    required String type,
    required String clientRequestId,
  }) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.conversationsSendMessage,
      parameters: <String, dynamic>{
        'workspaceId': workspaceId,
        'conversationId': conversationId,
        'content': content.trim(),
        'type': type,
        'clientRequestId': clientRequestId,
      },
    );
    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data) => SendMessageResult(
          message: MessageModel.fromJson(_requiredMap(data, 'message')),
          conversation: ConversationModel.fromJson(
            _requiredMap(data, 'conversation'),
          ),
        ),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }

  @override
  Future<ConversationModel> assign({
    required String workspaceId,
    required String conversationId,
    String? userId,
  }) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.conversationsAssign,
      parameters: <String, dynamic>{
        'workspaceId': workspaceId,
        'conversationId': conversationId,
        'userId': userId,
      },
    );
    return _conversation(result);
  }

  @override
  Future<ConversationModel> setMode({
    required String workspaceId,
    required String conversationId,
    required String mode,
  }) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.conversationsSetMode,
      parameters: <String, dynamic>{
        'workspaceId': workspaceId,
        'conversationId': conversationId,
        'mode': mode,
      },
    );
    return _conversation(result);
  }

  static ConversationThread _thread(
    Map<String, dynamic> data,
    ApiMeta meta,
  ) {
    final contextData = data['context'] is Map
        ? Map<String, dynamic>.from(data['context'] as Map)
        : const <String, dynamic>{};
    return ConversationThread(
      conversation: ConversationModel.fromJson(
        _requiredMap(data, 'conversation'),
      ),
      messages: _maps(data['messages'])
          .map(MessageModel.fromJson)
          .toList(growable: false)
        ..sort(
          (MessageModel first, MessageModel second) =>
              first.sentAt.compareTo(second.sentAt),
        ),
      lead: LeadModel.fromJson(_requiredMap(data, 'lead')),
      context: ConversationSalesContext.fromJson(contextData),
      owners: _maps(data['owners'])
          .map(ConversationOwnerModel.fromJson)
          .where(
            (ConversationOwnerModel item) =>
                item.id.isNotEmpty && item.name.isNotEmpty,
          )
          .toList(growable: false),
      suggestedReply: data['suggestedReply']?.toString(),
      nextMessagesCursor:
          meta.nextCursor ?? data['nextMessagesCursor']?.toString(),
      correlationId: meta.correlationId,
    );
  }

  static ConversationModel _conversation(
    ApiResult<Map<String, dynamic>> result,
  ) {
    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data) =>
        ConversationModel.fromJson(_requiredMap(data, 'conversation')),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }

  static Map<String, dynamic> _requiredMap(
    Map<String, dynamic> data,
    String key,
  ) {
    final raw = data[key];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw ApiException(
      code: 'INTERNAL_ERROR',
      message: 'A API não retornou o campo obrigatório "$key".',
    );
  }

  static Iterable<Map<String, dynamic>> _maps(dynamic raw) {
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw.whereType<Map>().map(Map<String, dynamic>.from);
  }
}
