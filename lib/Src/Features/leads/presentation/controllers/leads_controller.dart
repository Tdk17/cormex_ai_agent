import 'dart:async';

import 'package:agente_vendas_saas/Src/Core/api/api_exception.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:agente_vendas_saas/Src/Features/leads/domain/lead_filters.dart';
import 'package:agente_vendas_saas/Src/Features/leads/domain/leads_repository.dart';
import 'package:agente_vendas_saas/Src/Shared/models/lead_model.dart';
import 'package:signals/signals.dart';

class LeadsController {
  LeadsController(this._repository, this._authController) {
    _disposeWorkspaceEffect = effect(() {
      final workspaceId = _workspaceId;
      if (_observedWorkspaceId == workspaceId) return;
      _observedWorkspaceId = workspaceId;
      batch(() {
        leads.value = const <LeadModel>[];
        nextCursor.value = null;
        state.value = ScreenState.initial;
      });
      if (workspaceId != null) unawaited(load(force: true));
    });
  }

  final LeadsRepository _repository;
  final AuthController _authController;
  Timer? _searchDebounce;
  String? _observedWorkspaceId;
  late final void Function() _disposeWorkspaceEffect;

  final Signal<ScreenState> state = signal(ScreenState.initial);
  final Signal<List<LeadModel>> leads = signal<List<LeadModel>>(const <LeadModel>[]);
  final Signal<LeadFilters> filters = signal(const LeadFilters());
  final Signal<String?> nextCursor = signal<String?>(null);
  final Signal<bool> isLoadingMore = signal(false);
  final Signal<String?> errorMessage = signal<String?>(null);
  final Signal<String?> correlationId = signal<String?>(null);

  bool get hasMore => nextCursor.value != null;

  LeadModel? findById(String leadId) {
    for (final lead in leads.value) {
      if (lead.id == leadId) return lead;
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
        leads.value = page.items;
        nextCursor.value = page.nextCursor;
        correlationId.value = page.correlationId;
        state.value = page.items.isEmpty ? ScreenState.empty : ScreenState.success;
      });
    } on ApiException catch (error) {
      _setError(error.userMessage, error.correlationId);
    } on Object {
      _setError('Não foi possível carregar os leads.', null);
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
      batch(() {
        leads.value = <LeadModel>[...leads.value, ...page.items];
        nextCursor.value = page.nextCursor;
        correlationId.value = page.correlationId;
      });
    } on ApiException catch (error) {
      batch(() {
        errorMessage.value = error.userMessage;
        correlationId.value = error.correlationId;
      });
    } on Object {
      errorMessage.value = 'Não foi possível carregar mais leads.';
    } finally {
      isLoadingMore.value = false;
    }
  }

  void search(String value) {
    filters.value = filters.value.copyWith(search: value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () => load(force: true));
  }

  Future<void> applyFilters(LeadFilters value) async {
    filters.value = LeadFilters(
      search: filters.value.search,
      status: value.status,
      source: value.source,
      tag: value.tag,
    );
    await load(force: true);
  }

  Future<void> clearFilters() => applyFilters(const LeadFilters());

  void upsert(LeadModel lead) {
    final current = <LeadModel>[...leads.value];
    final index = current.indexWhere((LeadModel item) => item.id == lead.id);
    if (!_matchesCurrentFilters(lead)) {
      if (index >= 0) {
        current.removeAt(index);
        leads.value = current;
        state.value = current.isEmpty ? ScreenState.empty : ScreenState.success;
      }
      return;
    }
    if (index < 0) {
      current.insert(0, lead);
    } else {
      current[index] = lead;
    }
    leads.value = current;
    state.value = ScreenState.success;
  }

  bool _matchesCurrentFilters(LeadModel lead) {
    final currentFilters = filters.value;
    final search = currentFilters.search.trim().toLowerCase();
    final haystack = <String?>[
      lead.name,
      lead.phone,
      lead.email,
      lead.company,
      ...lead.tags,
    ].whereType<String>().join(' ').toLowerCase();
    return (search.isEmpty || haystack.contains(search)) &&
        (currentFilters.status == null || lead.status == currentFilters.status) &&
        (currentFilters.source == null || lead.source == currentFilters.source) &&
        (currentFilters.tag == null || lead.tags.contains(currentFilters.tag));
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
