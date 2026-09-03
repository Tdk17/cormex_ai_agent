import 'dart:async';

import 'package:agente_vendas_saas/Src/Core/api/api_exception.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:agente_vendas_saas/Src/Features/knowledge/domain/knowledge_models.dart';
import 'package:agente_vendas_saas/Src/Features/knowledge/domain/knowledge_repository.dart';
import 'package:signals/signals.dart';

class KnowledgeController {
  KnowledgeController(this._repository, this._authController) {
    _disposeWorkspaceEffect = effect(() {
      final workspaceId = _workspaceId;
      if (_observedWorkspaceId == workspaceId) return;
      _observedWorkspaceId = workspaceId;
      _pollTimer?.cancel();
      batch(() {
        sources.value = const <KnowledgeSourceModel>[];
        state.value = ScreenState.initial;
        nextCursor.value = null;
      });
      if (workspaceId != null) unawaited(load(force: true));
    });
  }

  static const int maxFileBytes = 15 * 1024 * 1024;
  final KnowledgeRepository _repository;
  final AuthController _authController;
  late final void Function() _disposeWorkspaceEffect;
  Timer? _searchDebounce;
  Timer? _pollTimer;
  String? _observedWorkspaceId;

  final Signal<ScreenState> state = signal(ScreenState.initial);
  final Signal<List<KnowledgeSourceModel>> sources =
      signal<List<KnowledgeSourceModel>>(const <KnowledgeSourceModel>[]);
  final Signal<String> searchText = signal('');
  final Signal<String?> typeFilter = signal<String?>(null);
  final Signal<String?> statusFilter = signal<String?>(null);
  final Signal<String?> nextCursor = signal<String?>(null);
  final Signal<bool> isLoadingMore = signal(false);
  final Signal<bool> isMutating = signal(false);
  final Signal<double> uploadProgress = signal(0);
  final Signal<String?> errorMessage = signal<String?>(null);
  final Signal<String?> successMessage = signal<String?>(null);
  final Signal<String?> correlationId = signal<String?>(null);

  Future<void> load({bool force = false}) async {
    if (!force && state.value == ScreenState.loading) return;
    final workspaceId = _workspaceId;
    if (workspaceId == null) return;
    batch(() {
      state.value = ScreenState.loading;
      errorMessage.value = null;
      correlationId.value = null;
    });
    try {
      final page = await _repository.list(
        workspaceId: workspaceId,
        search: searchText.value,
        type: typeFilter.value,
        status: statusFilter.value,
      );
      if (_workspaceId != workspaceId) return;
      batch(() {
        sources.value = page.items;
        nextCursor.value = page.nextCursor;
        correlationId.value = page.correlationId;
        state.value = page.items.isEmpty ? ScreenState.empty : ScreenState.success;
      });
      _schedulePoll();
    } on ApiException catch (error) {
      _setError(error.userMessage, error.correlationId, pageError: true);
    } on Object {
      _setError('Não foi possível carregar a Base de Conhecimento.', null,
          pageError: true);
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
        search: searchText.value,
        type: typeFilter.value,
        status: statusFilter.value,
        cursor: cursor,
      );
      final ids = sources.value.map((KnowledgeSourceModel item) => item.id).toSet();
      batch(() {
        sources.value = <KnowledgeSourceModel>[
          ...sources.value,
          ...page.items.where((KnowledgeSourceModel item) => ids.add(item.id)),
        ];
        nextCursor.value = page.nextCursor;
      });
      _schedulePoll();
    } on ApiException catch (error) {
      _setError(error.userMessage, error.correlationId);
    } on Object {
      errorMessage.value = 'Não foi possível carregar mais fontes.';
    } finally {
      isLoadingMore.value = false;
    }
  }

  void search(String value) {
    searchText.value = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 450),
      () => load(force: true),
    );
  }

  Future<void> setType(String? value) async {
    typeFilter.value = value;
    await load(force: true);
  }

  Future<void> setStatus(String? value) async {
    statusFilter.value = value;
    await load(force: true);
  }

  Future<bool> create(KnowledgeSourceInput input) async {
    final workspaceId = _workspaceId;
    if (workspaceId == null || isMutating.value) return false;
    batch(() {
      isMutating.value = true;
      errorMessage.value = null;
      successMessage.value = null;
    });
    try {
      final source = await _repository.create(
        workspaceId: workspaceId,
        input: input,
        clientRequestId:
            'knowledge_${DateTime.now().microsecondsSinceEpoch}',
      );
      _upsert(source);
      successMessage.value = 'Fonte adicionada e enviada para processamento.';
      _schedulePoll();
      return true;
    } on ApiException catch (error) {
      _setError(error.userMessage, error.correlationId);
      return false;
    } on Object {
      errorMessage.value = 'Não foi possível adicionar a fonte.';
      return false;
    } finally {
      isMutating.value = false;
    }
  }

  Future<bool> upload(KnowledgeFileInput input) async {
    final workspaceId = _workspaceId;
    if (workspaceId == null || isMutating.value) return false;
    if (input.bytes.isEmpty || input.bytes.length > maxFileBytes) {
      errorMessage.value = 'O arquivo deve ter até 15 MB.';
      return false;
    }
    batch(() {
      isMutating.value = true;
      uploadProgress.value = 0;
      errorMessage.value = null;
      successMessage.value = null;
    });
    try {
      final source = await _repository.uploadFile(
        workspaceId: workspaceId,
        input: input,
        clientRequestId:
            'knowledge_file_${DateTime.now().microsecondsSinceEpoch}',
        onSendProgress: (int sent, int total) {
          if (total > 0) uploadProgress.value = sent / total;
        },
      );
      _upsert(source);
      successMessage.value = 'Arquivo enviado e adicionado ao processamento.';
      _schedulePoll();
      return true;
    } on ApiException catch (error) {
      _setError(error.userMessage, error.correlationId);
      return false;
    } on Object {
      errorMessage.value = 'Não foi possível enviar o arquivo.';
      return false;
    } finally {
      isMutating.value = false;
    }
  }

  Future<bool> deleteSource(String sourceId) async {
    final workspaceId = _workspaceId;
    if (workspaceId == null || isMutating.value) return false;
    isMutating.value = true;
    try {
      await _repository.delete(workspaceId: workspaceId, sourceId: sourceId);
      sources.value = sources.value
          .where((KnowledgeSourceModel item) => item.id != sourceId)
          .toList(growable: false);
      state.value = sources.value.isEmpty ? ScreenState.empty : ScreenState.success;
      successMessage.value = 'Fonte excluída.';
      return true;
    } on ApiException catch (error) {
      _setError(error.userMessage, error.correlationId);
      return false;
    } on Object {
      errorMessage.value = 'Não foi possível excluir a fonte.';
      return false;
    } finally {
      isMutating.value = false;
    }
  }

  void clearFeedback() {
    errorMessage.value = null;
    successMessage.value = null;
  }

  void _upsert(KnowledgeSourceModel source) {
    final items = <KnowledgeSourceModel>[...sources.value];
    final index = items.indexWhere((KnowledgeSourceModel item) => item.id == source.id);
    if (index < 0) {
      items.insert(0, source);
    } else {
      items[index] = source;
    }
    sources.value = items;
    state.value = ScreenState.success;
  }

  void _schedulePoll() {
    _pollTimer?.cancel();
    if (!sources.value.any((KnowledgeSourceModel item) => item.status == 'processing')) {
      return;
    }
    _pollTimer = Timer(
      const Duration(seconds: 6),
      () => load(force: true),
    );
  }

  String? get _workspaceId =>
      _authController.session.value?.selectedWorkspace?.id;

  void _setError(
    String message,
    String? requestCorrelationId, {
    bool pageError = false,
  }) {
    batch(() {
      errorMessage.value = message;
      correlationId.value = requestCorrelationId;
      if (pageError) state.value = ScreenState.error;
    });
  }

  void dispose() {
    _searchDebounce?.cancel();
    _pollTimer?.cancel();
    _disposeWorkspaceEffect();
  }
}
