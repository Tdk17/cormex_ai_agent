import 'package:agente_vendas_saas/Src/Features/followups/domain/followup_rule_input.dart';
import 'package:agente_vendas_saas/Src/Shared/models/followup_models.dart';

class FollowUpsPageResult {
  const FollowUpsPageResult({
    required this.items,
    this.nextCursor,
    this.correlationId,
  });

  final List<FollowUpRuleModel> items;
  final String? nextCursor;
  final String? correlationId;
}

abstract interface class FollowUpsRepository {
  Future<FollowUpsPageResult> list({
    required String workspaceId,
    String? search,
    String? cursor,
    int limit = 30,
  });

  Future<FollowUpRuleModel> upsert({
    required String workspaceId,
    required FollowUpRuleInput input,
    required String clientRequestId,
    String? followupId,
  });
}
