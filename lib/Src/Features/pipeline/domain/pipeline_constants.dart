class PipelineStageIds {
  const PipelineStageIds._();

  static const String newLead = 'new_lead';
  static const String contacted = 'contacted';
  static const String proposal = 'proposal';
  static const String negotiation = 'negotiation';
  static const String closed = 'closed';

  static const List<String> ordered = <String>[
    newLead,
    contacted,
    proposal,
    negotiation,
    closed,
  ];
}

class OpportunityOutcomes {
  const OpportunityOutcomes._();

  static const String open = 'open';
  static const String won = 'won';
  static const String lost = 'lost';
}
