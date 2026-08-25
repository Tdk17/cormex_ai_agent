import 'package:agente_vendas_saas/Src/Core/api/api_exception.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:agente_vendas_saas/Src/Features/conversations/domain/conversation_constants.dart';
import 'package:agente_vendas_saas/Src/Features/conversations/domain/conversation_thread.dart';
import 'package:agente_vendas_saas/Src/Features/conversations/domain/conversations_repository.dart';
import 'package:agente_vendas_saas/Src/Features/conversations/presentation/controllers/conversations_controller.dart';
import 'package:agente_vendas_saas/Src/Shared/models/conversation_models.dart';
import 'package:agente_vendas_saas/Src/Shared/models/lead_model.dart';
import 'package:signals/signals.dart';

class ConversationThreadController {
  ConversationThreadController(
    this._repository,
    this._authController,
    this._conversationsController,
  );

  final ConversationsRepository _repository;
  final AuthController _authController;
  final ConversationsController _conversationsController;

  final Signal<ScreenState> state = signal(ScreenState.initial);
  final Signal<ConversationModel?> conversation =
      signal<ConversationModel?>(null);
  final Signal<List<MessageModel>> messages =
      signal<List<MessageModel>>(const <MessageModel>[]);
  final Signal<LeadModel?> lead = signal<LeadModel?>(null);
  final Signal<ConversationSalesContext> salesContext =
      signal(const ConversationSalesContext());
  final Signal<List<ConversationOwnerModel>> owners =
      signal<List<ConversationOwnerModel>>(const <ConversationOwnerModel>[]);
  final Signal<String?> suggestedReply = signal<String?>(null);
  final Signal<String?> nextMessagesCursor = signal<String?>(null);
  final Signal<bool> isLoadingOlder = signal(false);
  final Signal<bool> isSending = signal(false);
  final Signal<bool> isChangingMode = signal(false);
  final Signal<bool> isChangingAssignment = signal(false);
  final Signal<String?> errorMessage = signal<String?>(null);
  final Signal<String?> actionError = signal<String?>(null);
  final Signal<String?> correlationId = signal<String?>(null);

  String? _conversationId;
  int _requestSequence = 0;
  String? _pendingContent;
  String? _pendingRequestId;

  bool get hasOlderMessages =>
      nextMessagesCursor.value != null && nextMessagesCursor.value!.isNotEmpty;

  Future<void> reload() async {
    final conversationId = _conversationId;
    if (conversationId != null) await load(conversationId, force: true);
  }

  Future<void> load(String conversationId, {bool force = false}) async {
    if (!force &&
        _conversationId == conversationId &&
        state.value == ScreenState.loading) {
      return;
    }
    final workspaceId = _workspaceId;
    if (workspaceId == null) return;
    _conversationId = conversationId;
    final cached = _conversationsController.findById(conversationId);
    batch(() {
      if (cached != null) conversation.value = cached;
      state.value = ScreenState.loading;
      errorMessage.value = null;
      actionError.value = null;
    });

    try {
      final thread = await _repository.get(
        workspaceId: workspaceId,
        conversationId: conversationId,
      );
      batch(() {
        conversation.value = thread.conversation;
        messages.value = thread.messages;
        lead.value = thread.lead;
        salesContext.value = thread.context;
        owners.value = thread.owners;
        suggestedReply.value = thread.suggestedReply;
        nextMessagesCursor.value = thread.nextMessagesCursor;
        correlationId.value = thread.correlationId;
        state.value = ScreenState.success;
      });
      _conversationsController
        ..upsert(thread.conversation.copyWith(unreadCount: 0))
        ..markRead(conversationId);
    } on ApiException catch (error) {
      _setPageError(error.userMessage, error.correlationId);
    } on Object {
      _setPageError('Não foi possível carregar a conversa.', null);
    }
  }

  Future<void> loadOlder() async {
    final workspaceId = _workspaceId;
    final conversationId = _conversationId;
    final cursor = nextMessagesCursor.value;
    if (workspaceId == null ||
        conversationId == null ||
        cursor == null ||
        isLoadingOlder.value) {
      return;
    }
    isLoadingOlder.value = true;
    try {
      final thread = await _repository.get(
        workspaceId: workspaceId,
        conversationId: conversationId,
        messagesCursor: cursor,
      );
      final knownIds = messages.value.map((MessageModel item) => item.id).toSet();
      final older = thread.messages
          .where((MessageModel item) => knownIds.add(item.id))
          .toList(growable: false);
      batch(() {
        messages.value = <MessageModel>[...older, ...messages.value]
          ..sort(
            (MessageModel first, MessageModel second) =>
                first.sentAt.compareTo(second.sentAt),
          );
        nextMessagesCursor.value = thread.nextMessagesCursor;
        correlationId.value = thread.correlationId;
      });
    } on ApiException catch (error) {
      _setActionError(error.userMessage, error.correlationId);
    } on Object {
      actionError.value = 'Não foi possível carregar mensagens anteriores.';
    } finally {
      isLoadingOlder.value = false;
    }
  }

  Future<bool> send(String rawContent) async {
    final workspaceId = _workspaceId;
    final conversationId = _conversationId;
    final content = rawContent.trim();
    if (workspaceId == null || conversationId == null || isSending.value) {
      return false;
    }
    if (content.isEmpty) return false;
    if (content.length > 4000) {
      actionError.value = 'A mensagem deve ter no máximo 4.000 caracteres.';
      return false;
    }
    if (conversation.value?.status == ConversationStatuses.closed) {
      actionError.value = 'Reabra a conversa antes de enviar uma mensagem.';
      return false;
    }

    final clientRequestId = _pendingContent == content &&
            _pendingRequestId != null
        ? _pendingRequestId!
        : 'flutter_${conversationId}_${DateTime.now().microsecondsSinceEpoch}_${_requestSequence++}';
    _pendingContent = content;
    _pendingRequestId = clientRequestId;
    batch(() {
      isSending.value = true;
      actionError.value = null;
    });
    try {
      final result = await _repository.sendMessage(
        workspaceId: workspaceId,
        conversationId: conversationId,
        content: content,
        type: 'text',
        clientRequestId: clientRequestId,
      );
      final current = <MessageModel>[...messages.value];
      final index = current.indexWhere(
        (MessageModel item) => item.id == result.message.id,
      );
      if (index < 0) {
        current.add(result.message);
      } else {
        current[index] = result.message;
      }
      current.sort(
        (MessageModel first, MessageModel second) =>
            first.sentAt.compareTo(second.sentAt),
      );
      batch(() {
        messages.value = current;
        conversation.value = result.conversation;
        suggestedReply.value = null;
      });
      _conversationsController.upsert(result.conversation);
      _pendingContent = null;
      _pendingRequestId = null;
      return true;
    } on ApiException catch (error) {
      _setActionError(error.userMessage, error.correlationId);
      return false;
    } on Object {
      actionError.value = 'Não foi possível enviar a mensagem.';
      return false;
    } finally {
      isSending.value = false;
    }
  }

  Future<void> setMode(String mode) async {
    if (!ConversationModes.values.contains(mode) || isChangingMode.value) return;
    final workspaceId = _workspaceId;
    final conversationId = _conversationId;
    if (workspaceId == null || conversationId == null) return;
    batch(() {
      isChangingMode.value = true;
      actionError.value = null;
    });
    try {
      final updated = await _repository.setMode(
        workspaceId: workspaceId,
        conversationId: conversationId,
        mode: mode,
      );
      _applyConversation(updated);
    } on ApiException catch (error) {
      _setActionError(error.userMessage, error.correlationId);
    } on Object {
      actionError.value = 'Não foi possível alterar o modo de atendimento.';
    } finally {
      isChangingMode.value = false;
    }
  }

  Future<void> assign(String? userId) async {
    if (isChangingAssignment.value) return;
    final workspaceId = _workspaceId;
    final conversationId = _conversationId;
    if (workspaceId == null || conversationId == null) return;
    batch(() {
      isChangingAssignment.value = true;
      actionError.value = null;
    });
    try {
      final updated = await _repository.assign(
        workspaceId: workspaceId,
        conversationId: conversationId,
        userId: userId,
      );
      _applyConversation(updated);
    } on ApiException catch (error) {
      _setActionError(error.userMessage, error.correlationId);
    } on Object {
      actionError.value = 'Não foi possível alterar o responsável.';
    } finally {
      isChangingAssignment.value = false;
    }
  }

  Future<void> takeOver() async {
    if (isChangingAssignment.value || isChangingMode.value) return;
    final userId = _authController.session.value?.user.id;
    if (userId == null || userId.isEmpty) return;
    await assign(userId);
    if (conversation.value?.assignedUserId == userId) {
      await setMode(ConversationModes.human);
    }
  }

  Future<void> returnToAi() async {
    if (isChangingAssignment.value || isChangingMode.value) return;
    await setMode(ConversationModes.auto);
    if (conversation.value?.agentMode == ConversationModes.auto) {
      await assign(null);
    }
  }

  void clearActionError() => actionError.value = null;

  void _applyConversation(ConversationModel updated) {
    conversation.value = updated;
    _conversationsController.upsert(updated);
  }

  String? get _workspaceId =>
      _authController.session.value?.selectedWorkspace?.id;

  void _setPageError(String message, String? requestCorrelationId) {
    batch(() {
      errorMessage.value = message;
      correlationId.value = requestCorrelationId;
      state.value = ScreenState.error;
    });
  }

  void _setActionError(String message, String? requestCorrelationId) {
    batch(() {
      actionError.value = message;
      correlationId.value = requestCorrelationId;
    });
  }
}
