import 'package:agente_vendas_saas/Src/Core/api/api_exception.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:agente_vendas_saas/Src/Features/leads/domain/lead_filters.dart';
import 'package:agente_vendas_saas/Src/Features/leads/domain/leads_repository.dart';
import 'package:agente_vendas_saas/Src/Features/pipeline/domain/opportunity_input.dart';
import 'package:agente_vendas_saas/Src/Features/pipeline/domain/pipeline_constants.dart';
import 'package:agente_vendas_saas/Src/Features/pipeline/domain/pipeline_repository.dart';
import 'package:agente_vendas_saas/Src/Features/pipeline/presentation/controllers/pipeline_controller.dart';
import 'package:agente_vendas_saas/Src/Shared/models/lead_model.dart';
import 'package:agente_vendas_saas/Src/Shared/models/pipeline_models.dart';
import 'package:signals/signals.dart';

class OpportunityFormController {
  OpportunityFormController(
    this._repository,
    this._leadsRepository,
    this._authController,
    this._pipelineController,
  );

  final PipelineRepository _repository;
  final LeadsRepository _leadsRepository;
  final AuthController _authController;
  final PipelineController _pipelineController;

  final Signal<ScreenState> loadState = signal(ScreenState.initial);
  final Signal<List<LeadModel>> leads = signal<List<LeadModel>>(const <LeadModel>[]);
  final Signal<OpportunityModel?> opportunity = signal<OpportunityModel?>(null);
  final Signal<bool> isSaving = signal(false);
  final Signal<String?> errorMessage = signal<String?>(null);
  final Signal<String?> correlationId = signal<String?>(null);

  List<PipelineStageModel> get stages => _pipelineController.stages.value;
  List<({String id, String name})> get owners {
    final result = <({String id, String name})>[
      ..._pipelineController.owners,
    ];
    final current = opportunity.value;
    final currentOwnerId = current?.ownerId;
    final currentOwnerName = current?.ownerName;
    if (currentOwnerId != null &&
        currentOwnerId.isNotEmpty &&
        currentOwnerName != null &&
        currentOwnerName.isNotEmpty &&
        !result.any((item) => item.id == currentOwnerId)) {
      result.add((id: currentOwnerId, name: currentOwnerName));
    }
    result.sort((first, second) => first.name.compareTo(second.name));
    return result;
  }

  Future<void> initialize({String? opportunityId}) async {
    final workspaceId = _workspaceId;
    if (workspaceId == null) return;
    batch(() {
      loadState.value = ScreenState.loading;
      errorMessage.value = null;
    });
    try {
      if (_pipelineController.stages.value.isEmpty) {
        await _pipelineController.load(force: true);
      }
      if (_pipelineController.stages.value.isEmpty) {
        throw ApiException(
          code: 'INTERNAL_ERROR',
          message: _pipelineController.errorMessage.value ??
              'A API não retornou as etapas do pipeline.',
          correlationId: _pipelineController.correlationId.value,
        );
      }
      final leadPage = await _leadsRepository.list(
        workspaceId: workspaceId,
        filters: const LeadFilters(),
        limit: 100,
      );
      final loadedLeads = <LeadModel>[...leadPage.items];
      OpportunityModel? current;
      if (opportunityId != null) {
        final currentOpportunity =
            _pipelineController.findById(opportunityId) ??
            await _repository.get(
              workspaceId: workspaceId,
              opportunityId: opportunityId,
            );
        current = currentOpportunity;
        if (currentOpportunity.leadId.isNotEmpty &&
            !loadedLeads.any(
              (LeadModel lead) => lead.id == currentOpportunity.leadId,
            )) {
          loadedLeads.add(
            await _leadsRepository.get(
              workspaceId: workspaceId,
              leadId: currentOpportunity.leadId,
            ),
          );
        }
      }
      batch(() {
        leads.value = loadedLeads;
        opportunity.value = current;
        loadState.value = ScreenState.success;
      });
    } on ApiException catch (error) {
      batch(() {
        errorMessage.value = error.userMessage;
        correlationId.value = error.correlationId;
        loadState.value = ScreenState.error;
      });
    } on Object {
      batch(() {
        errorMessage.value = 'Não foi possível preparar o formulário.';
        loadState.value = ScreenState.error;
      });
    }
  }

  Future<OpportunityModel?> save({
    String? opportunityId,
    required OpportunityInput input,
  }) async {
    final validation = validate(input);
    if (validation != null) {
      errorMessage.value = validation;
      return null;
    }
    final workspaceId = _workspaceId;
    if (workspaceId == null || isSaving.value) return null;

    batch(() {
      isSaving.value = true;
      errorMessage.value = null;
      correlationId.value = null;
    });
    try {
      final saved = opportunityId == null
          ? await _repository.create(workspaceId: workspaceId, input: input)
          : await _repository.update(
              workspaceId: workspaceId,
              opportunityId: opportunityId,
              input: input,
            );
      _pipelineController.upsert(saved);
      return saved;
    } on ApiException catch (error) {
      batch(() {
        errorMessage.value = error.userMessage;
        correlationId.value = error.correlationId;
      });
    } on Object {
      errorMessage.value = 'Não foi possível salvar a oportunidade.';
    } finally {
      isSaving.value = false;
    }
    return null;
  }

  String? validate(OpportunityInput input) {
    if (input.leadId.isEmpty) return 'Selecione um lead.';
    if (input.companyName.trim().length < 2) return 'Informe a empresa.';
    if (input.contactName.trim().length < 2) return 'Informe o contato.';
    if (input.title.trim().length < 2) return 'Informe o título da oportunidade.';
    if (input.value < 0) return 'O valor não pode ser negativo.';
    if (input.probability < 0 || input.probability > 100) {
      return 'A probabilidade deve ficar entre 0 e 100.';
    }
    if (!stages.any((PipelineStageModel stage) => stage.id == input.stageId)) {
      return 'Selecione uma etapa válida.';
    }
    if (input.stageId == PipelineStageIds.closed &&
        input.outcome != OpportunityOutcomes.won &&
        input.outcome != OpportunityOutcomes.lost) {
      return 'Informe se a oportunidade foi ganha ou perdida.';
    }
    if (input.stageId != PipelineStageIds.closed &&
        input.outcome != OpportunityOutcomes.open) {
      return 'Somente oportunidades fechadas podem ser ganhas ou perdidas.';
    }
    return null;
  }

  String? get _workspaceId =>
      _authController.session.value?.selectedWorkspace?.id;
}
