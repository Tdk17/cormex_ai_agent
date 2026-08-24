import 'dart:async';

import 'package:agente_vendas_saas/Src/Core/api/api_exception.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:agente_vendas_saas/Src/Features/pipeline/domain/pipeline_board.dart';
import 'package:agente_vendas_saas/Src/Features/pipeline/domain/pipeline_constants.dart';
import 'package:agente_vendas_saas/Src/Features/pipeline/domain/pipeline_repository.dart';
import 'package:agente_vendas_saas/Src/Shared/models/pipeline_models.dart';
import 'package:signals/signals.dart';

class PipelineController {
  PipelineController(this._repository, this._authController) {
    _disposeWorkspaceEffect = effect(() {
      final workspaceId = _workspaceId;
      if (_observedWorkspaceId == workspaceId) return;
      _observedWorkspaceId = workspaceId;
      batch(() {
        stages.value = const <PipelineStageModel>[];
        opportunities.value = const <OpportunityModel>[];
        availableOwners.value = const <PipelineOwnerModel>[];
        search.value = '';
        ownerId.value = null;
        movingIds.value = const <String>{};
        errorMessage.value = null;
        correlationId.value = null;
        actionError.value = null;
        state.value = ScreenState.initial;
      });
      if (workspaceId != null) unawaited(load(force: true));
    });
  }

  final PipelineRepository _repository;
  final AuthController _authController;
  String? _observedWorkspaceId;
  late final void Function() _disposeWorkspaceEffect;

  final Signal<ScreenState> state = signal(ScreenState.initial);
  final Signal<List<PipelineStageModel>> stages =
      signal<List<PipelineStageModel>>(const <PipelineStageModel>[]);
  final Signal<List<OpportunityModel>> opportunities =
      signal<List<OpportunityModel>>(const <OpportunityModel>[]);
  final Signal<List<PipelineOwnerModel>> availableOwners =
      signal<List<PipelineOwnerModel>>(const <PipelineOwnerModel>[]);
  final Signal<String> search = signal('');
  final Signal<String?> ownerId = signal<String?>(null);
  final Signal<Set<String>> movingIds = signal<Set<String>>(const <String>{});
  final Signal<String?> errorMessage = signal<String?>(null);
  final Signal<String?> correlationId = signal<String?>(null);
  final Signal<String?> actionError = signal<String?>(null);

  late final summary = computed(() {
    final items = opportunities.value;
    final negotiation = items.where(
      (OpportunityModel item) =>
          item.stageId == PipelineStageIds.negotiation &&
          item.outcome == OpportunityOutcomes.open,
    );
    final won = items.where(
      (OpportunityModel item) => item.outcome == OpportunityOutcomes.won,
    );
    final lost = items.where(
      (OpportunityModel item) => item.outcome == OpportunityOutcomes.lost,
    );
    return PipelineSummary(
      leadsCount: items.length,
      leadsValue: _sum(items),
      negotiationCount: negotiation.length,
      negotiationValue: _sum(negotiation),
      wonCount: won.length,
      wonValue: _sum(won),
      lostCount: lost.length,
      lostValue: _sum(lost),
    );
  });

  List<OpportunityModel> opportunitiesFor(String stageId) {
    final query = search.value.trim().toLowerCase();
    final selectedOwnerId = ownerId.value;
    final result = opportunities.value.where((OpportunityModel item) {
      final haystack = <String?>[
        item.title,
        item.companyName,
        item.contactName,
        item.product,
        item.ownerName,
      ].whereType<String>().join(' ').toLowerCase();
      return item.stageId == stageId &&
          (query.isEmpty || haystack.contains(query)) &&
          (selectedOwnerId == null || item.ownerId == selectedOwnerId);
    }).toList(growable: false)
      ..sort(
        (OpportunityModel first, OpportunityModel second) =>
            second.updatedAt.compareTo(first.updatedAt),
      );
    return result;
  }

  List<({String id, String name})> get owners {
    final unique = <String, String>{};
    for (final owner in availableOwners.value) {
      if (owner.id.isNotEmpty && owner.name.isNotEmpty) {
        unique[owner.id] = owner.name;
      }
    }
    for (final item in opportunities.value) {
      final id = item.ownerId;
      final name = item.ownerName;
      if (id != null && id.isNotEmpty && name != null && name.isNotEmpty) {
        unique[id] = name;
      }
    }
    final result = unique.entries
        .map((entry) => (id: entry.key, name: entry.value))
        .toList(growable: false)
      ..sort((first, second) => first.name.compareTo(second.name));
    return result;
  }

  OpportunityModel? findById(String opportunityId) {
    for (final item in opportunities.value) {
      if (item.id == opportunityId) return item;
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
      final board = await _repository.list(workspaceId: workspaceId);
      if (_workspaceId != workspaceId) return;
      if (board.stages.isEmpty) {
        throw const ApiException(
          code: 'INTERNAL_ERROR',
          message: 'A API não retornou as etapas do pipeline.',
        );
      }
      batch(() {
        stages.value = board.stages;
        opportunities.value = board.opportunities;
        availableOwners.value = board.owners;
        correlationId.value = board.correlationId;
        state.value = ScreenState.success;
      });
    } on ApiException catch (error) {
      if (_workspaceId != workspaceId) return;
      _setError(error.userMessage, error.correlationId);
    } on Object {
      if (_workspaceId != workspaceId) return;
      _setError('Não foi possível carregar o pipeline.', null);
    }
  }

  Future<bool> moveOpportunity({
    required OpportunityModel opportunity,
    required String toStageId,
    required String outcome,
  }) async {
    if (!stages.value.any((PipelineStageModel stage) => stage.id == toStageId)) {
      actionError.value = 'Selecione uma etapa válida.';
      return false;
    }
    final validOutcome = toStageId == PipelineStageIds.closed
        ? outcome == OpportunityOutcomes.won ||
            outcome == OpportunityOutcomes.lost
        : outcome == OpportunityOutcomes.open;
    if (!validOutcome) {
      actionError.value = 'A etapa e o resultado informados não são compatíveis.';
      return false;
    }
    if (opportunity.stageId == toStageId && opportunity.outcome == outcome) {
      return true;
    }
    if (movingIds.value.contains(opportunity.id)) return false;
    final workspaceId = _workspaceId;
    if (workspaceId == null) return false;

    final before = opportunities.value;
    final optimistic = opportunity.copyWith(
      stageId: toStageId,
      outcome: outcome,
      updatedAt: DateTime.now(),
    );
    batch(() {
      movingIds.value = <String>{...movingIds.value, opportunity.id};
      actionError.value = null;
      _replace(optimistic);
    });

    try {
      final saved = await _repository.move(
        workspaceId: workspaceId,
        opportunityId: opportunity.id,
        fromStageId: opportunity.stageId,
        toStageId: toStageId,
        outcome: outcome,
      );
      if (_workspaceId != workspaceId) return false;
      _replace(saved);
      return true;
    } on ApiException catch (error) {
      if (_workspaceId == workspaceId) {
        batch(() {
          opportunities.value = before;
          actionError.value = error.userMessage;
          correlationId.value = error.correlationId;
        });
      }
    } on Object {
      if (_workspaceId == workspaceId) {
        batch(() {
          opportunities.value = before;
          actionError.value = 'Não foi possível mover a oportunidade.';
        });
      }
    } finally {
      movingIds.value = <String>{...movingIds.value}..remove(opportunity.id);
    }
    return false;
  }

  void upsert(OpportunityModel opportunity) {
    _replace(opportunity, insertWhenMissing: true);
    state.value = ScreenState.success;
  }

  void clearActionError() => actionError.value = null;

  void dispose() => _disposeWorkspaceEffect();

  void _replace(
    OpportunityModel opportunity, {
    bool insertWhenMissing = false,
  }) {
    final current = <OpportunityModel>[...opportunities.value];
    final index = current.indexWhere(
      (OpportunityModel item) => item.id == opportunity.id,
    );
    if (index >= 0) {
      current[index] = opportunity;
    } else if (insertWhenMissing) {
      current.insert(0, opportunity);
    }
    opportunities.value = current;
  }

  String? get _workspaceId =>
      _authController.session.value?.selectedWorkspace?.id;

  static double _sum(Iterable<OpportunityModel> items) {
    return items.fold<double>(
      0,
      (double total, OpportunityModel item) => total + item.value,
    );
  }

  void _setError(String message, String? requestCorrelationId) {
    batch(() {
      errorMessage.value = message;
      correlationId.value = requestCorrelationId;
      state.value = ScreenState.error;
    });
  }
}
