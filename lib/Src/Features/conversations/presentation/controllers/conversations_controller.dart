import 'dart:async';

import 'package:agente_vendas_saas/Src/Core/api/api_exception.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:agente_vendas_saas/Src/Features/conversations/domain/conversation_filters.dart';
import 'package:agente_vendas_saas/Src/Features/conversations/domain/conversation_start_input.dart';
import 'package:agente_vendas_saas/Src/Features/conversations/domain/conversations_repository.dart';
import 'package:agente_vendas_saas/Src/Shared/models/conversation_models.dart';
import 'package:signals/signals.dart';

class ConversationsController {
  ConversationsController(this._repository, this._authController) {
    _disposeWorkspaceEffect = effect(() {
      final workspaceId = _workspaceId;
      if (_observedWorkspaceId == workspaceId) return;
      _observedWorkspaceId = workspaceId;
      batch(() {
        conversations.value = const <ConversationModel>[];
        owners.value = const <ConversationOwnerModel>[];
        nextCursor.value = null;
        filters.value = const ConversationFilters();
        state.value = ScreenState.initial;
      });
      if (workspaceId != null) unawaited(load(force: true));
    });
  }

  final ConversationsRepository _repository;
  final AuthController _authController;
  Timer? _searchDebounce;
  String? _observedWorkspaceId;
  late final void Function() _disposeWorkspaceEffect;

  final Signal<ScreenState> state = signal(ScreenState.initial);
  final Signal<List<ConversationModel>> conversations =
      signal<List<ConversationModel>>(const <ConversationModel>[]);
  final Signal<List<ConversationOwnerModel>> owners =
      signal<List<ConversationOwnerModel>>(const <ConversationOwnerModel>[]);
  final Signal<ConversationFilters> filters = signal(const ConversationFilters());
  final Signal<String?> nextCursor = signal<String?>(null);
  final Signal<bool> isLoadingMore = signal(false);
  final Signal<bool> isStarting = signal(false);
  final Signal<String?> errorMessage = signal<String?>(null);
  final Signal<String?> correlationId = signal<String?>(null);
  String? _pendingStartKey;
  String? _pendingStartRequestId;

  bool get hasMore => nextCursor.value != null && nextCursor.value!.isNotEmpty;

  ConversationModel? findById(String conversationId) {
    for (final conversation in conversations.value) {
      if (conversation.id == conversationId) return conversation;
    }
    return null;
  }

  Future<void> load({bool force = false}) async {
    if (!force && state.value == ScreenState.loading) return;
    final workspaceId = _workspaceId;
    if (workspaceId == null) {
      state.value = ScreenState.empty;
      return;
    }

    batch(() {
      state.value = ScreenState.loading;
      errorMessage.value = null;
      correlationId.value = null;
    });
    try {
      final page = await _repository.list(
        workspaceId: workspaceId,
        filters: filters.value,
      );
      batch(() {
        conversations.value = page.items;
        owners.value = page.owners;
        nextCursor.value = page.nextCursor;
        correlationId.value = page.correlationId;
        state.value = page.items.isEmpty ? ScreenState.empty : ScreenState.success;
      });
    } on ApiException catch (error) {
      _setError(error.userMessage, error.correlationId);
    } on Object {
      _setError('Não foi possível carregar as conversas.', null);
    }
  }

  Future<void> loadMore() async {
    final workspaceId = _workspaceId;
    final cursor = nextCursor.value;
    if (workspaceId == null || cursor == null || isLoadingMore.value) return;

    isLoadingMore.value = true;
    try {
      final page = await _repository.list(
        workspaceId: workspaceId,
        filters: filters.value,
        cursor: cursor,
      );
      final knownIds = conversations.value
          .map((ConversationModel item) => item.id)
          .toSet();
      batch(() {
        conversations.value = <ConversationModel>[
          ...conversations.value,
          ...page.items.where((ConversationModel item) => knownIds.add(item.id)),
        ];
        if (page.owners.isNotEmpty) owners.value = page.owners;
        nextCursor.value = page.nextCursor;
        correlationId.value = page.correlationId;
      });
    } on ApiException catch (error) {
      batch(() {
        errorMessage.value = error.userMessage;
        correlationId.value = error.correlationId;
      });
    } on Object {
      errorMessage.value = 'Não foi possível carregar mais conversas.';
    } finally {
      isLoadingMore.value = false;
    }
  }

  void search(String value) {
    filters.value = filters.value.copyWith(search: value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 450),
      () => load(force: true),
    );
  }

  Future<void> setChannel(String? value) async {
    filters.value = value == null
        ? filters.value.copyWith(clearChannel: true)
        : filters.value.copyWith(channel: value);
    await load(force: true);
  }

  Future<void> setStatus(String? value) async {
    filters.value = value == null
        ? filters.value.copyWith(clearStatus: true)
        : filters.value.copyWith(status: value);
    await load(force: true);
  }

  Future<void> setOwner(String? value) async {
    filters.value = value == null
        ? filters.value.copyWith(clearAssignedUser: true)
        : filters.value.copyWith(assignedUserId: value);
    await load(force: true);
  }

  void markRead(String conversationId) {
    final conversation = findById(conversationId);
    if (conversation == null || conversation.unreadCount == 0) return;
    upsert(conversation.copyWith(unreadCount: 0));
  }

  Future<ConversationModel?> startConversation(
    ConversationStartInput input,
  ) async {
    final workspaceId = _workspaceId;
    if (workspaceId == null || isStarting.value) return null;
    final hasDestination = input.leadId?.trim().isNotEmpty == true ||
        input.phone?.trim().isNotEmpty == true ||
        input.email?.trim().isNotEmpty == true;
    if (!hasDestination) {
      errorMessage.value =
          'Informe o telefone, o e-mail ou o identificador de um lead.';
      return null;
    }
    if (input.mode == 'human' &&
        (input.initialMessage?.trim().length ?? 0) < 2) {
      errorMessage.value = 'Escreva a primeira mensagem do atendimento.';
      return null;
    }

    final key = input.idempotencyKey;
    if (_pendingStartKey != key || _pendingStartRequestId == null) {
      _pendingStartKey = key;
      _pendingStartRequestId =
          'flutter_start_${DateTime.now().microsecondsSinceEpoch}';
    }
    batch(() {
      isStarting.value = true;
      errorMessage.value = null;
      correlationId.value = null;
    });
    try {
      final conversation = await _repository.start(
        workspaceId: workspaceId,
        input: input,
        clientRequestId: _pendingStartRequestId!,
      );
      _pendingStartKey = null;
      _pendingStartRequestId = null;
      upsert(conversation);
      return conversation;
    } on ApiException catch (error) {
      batch(() {
        errorMessage.value = error.userMessage;
        correlationId.value = error.correlationId;
      });
      return null;
    } on Object {
      errorMessage.value = 'Não foi possível iniciar a conversa.';
      return null;
    } finally {
      isStarting.value = false;
    }
  }

  void clearActionError() {
    if (state.value != ScreenState.error) {
      errorMessage.value = null;
      correlationId.value = null;
    }
  }

  void upsert(ConversationModel conversation) {
    final current = <ConversationModel>[...conversations.value];
    final index = current.indexWhere(
      (ConversationModel item) => item.id == conversation.id,
    );
    if (!_matchesCurrentFilters(conversation)) {
      if (index >= 0) {
        current.removeAt(index);
        conversations.value = current;
        state.value = current.isEmpty ? ScreenState.empty : ScreenState.success;
      }
      return;
    }
    if (index < 0) {
      current.insert(0, conversation);
    } else {
      current[index] = conversation;
    }
    current.sort(
      (ConversationModel first, ConversationModel second) =>
          second.updatedAt.compareTo(first.updatedAt),
    );
    conversations.value = current;
    state.value = ScreenState.success;
  }

  bool _matchesCurrentFilters(ConversationModel conversation) {
    final currentFilters = filters.value;
    final search = currentFilters.search.trim().toLowerCase();
    final haystack = <String?>[
      conversation.leadName,
      conversation.lastMessagePreview,
      conversation.assignedUserName,
    ].whereType<String>().join(' ').toLowerCase();
    return (search.isEmpty || haystack.contains(search)) &&
        (currentFilters.channel == null ||
            conversation.channel == currentFilters.channel) &&
        (currentFilters.status == null ||
            conversation.status == currentFilters.status) &&
        (currentFilters.assignedUserId == null ||
            conversation.assignedUserId == currentFilters.assignedUserId);
  }

  void dispose() {
    _searchDebounce?.cancel();
    _disposeWorkspaceEffect();
  }

  String? get _workspaceId =>
      _authController.session.value?.selectedWorkspace?.id;

  void _setError(String message, String? requestCorrelationId) {
    batch(() {
      errorMessage.value = message;
      correlationId.value = requestCorrelationId;
      state.value = ScreenState.error;
    });
  }
}
