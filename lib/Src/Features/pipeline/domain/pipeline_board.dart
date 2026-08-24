import 'package:agente_vendas_saas/Src/Shared/models/pipeline_models.dart';

class PipelineBoard {
  const PipelineBoard({
    required this.stages,
    required this.opportunities,
    this.owners = const <PipelineOwnerModel>[],
    this.correlationId,
  });

  final List<PipelineStageModel> stages;
  final List<OpportunityModel> opportunities;
  final List<PipelineOwnerModel> owners;
  final String? correlationId;
}

class PipelineSummary {
  const PipelineSummary({
    required this.leadsCount,
    required this.leadsValue,
    required this.negotiationCount,
    required this.negotiationValue,
    required this.wonCount,
    required this.wonValue,
    required this.lostCount,
    required this.lostValue,
  });

  final int leadsCount;
  final double leadsValue;
  final int negotiationCount;
  final double negotiationValue;
  final int wonCount;
  final double wonValue;
  final int lostCount;
  final double lostValue;
}
