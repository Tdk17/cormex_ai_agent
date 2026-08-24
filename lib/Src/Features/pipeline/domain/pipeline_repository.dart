import 'package:agente_vendas_saas/Src/Features/pipeline/domain/opportunity_input.dart';
import 'package:agente_vendas_saas/Src/Features/pipeline/domain/pipeline_board.dart';
import 'package:agente_vendas_saas/Src/Shared/models/pipeline_models.dart';

abstract interface class PipelineRepository {
  Future<PipelineBoard> list({required String workspaceId});

  Future<OpportunityModel> get({
    required String workspaceId,
    required String opportunityId,
  });

  Future<OpportunityModel> create({
    required String workspaceId,
    required OpportunityInput input,
  });

  Future<OpportunityModel> update({
    required String workspaceId,
    required String opportunityId,
    required OpportunityInput input,
  });

  Future<OpportunityModel> move({
    required String workspaceId,
    required String opportunityId,
    required String fromStageId,
    required String toStageId,
    required String outcome,
  });
}
