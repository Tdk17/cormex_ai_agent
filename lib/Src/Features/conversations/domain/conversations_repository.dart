import 'package:agente_vendas_saas/Src/Features/conversations/domain/conversation_filters.dart';
import 'package:agente_vendas_saas/Src/Features/conversations/domain/conversation_page.dart';
import 'package:agente_vendas_saas/Src/Features/conversations/domain/conversation_start_input.dart';
import 'package:agente_vendas_saas/Src/Features/conversations/domain/conversation_thread.dart';
import 'package:agente_vendas_saas/Src/Shared/models/conversation_models.dart';

abstract interface class ConversationsRepository {
  Future<ConversationPage> list({
    required String workspaceId,
    required ConversationFilters filters,
    String? cursor,
    int limit = 30,
  });

  Future<ConversationThread> get({
    required String workspaceId,
    required String conversationId,
    String? messagesCursor,
    int messagesLimit = 50,
  });

  Future<SendMessageResult> sendMessage({
    required String workspaceId,
    required String conversationId,
    required String content,
    required String type,
    required String clientRequestId,
  });

  Future<ConversationModel> assign({
    required String workspaceId,
    required String conversationId,
    String? userId,
  });

  Future<ConversationModel> setMode({
    required String workspaceId,
    required String conversationId,
    required String mode,
  });

  Future<ConversationModel> start({
    required String workspaceId,
    required ConversationStartInput input,
    required String clientRequestId,
  });
}
