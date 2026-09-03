import 'package:agente_vendas_saas/Src/Core/api/api_result.dart';
import 'package:agente_vendas_saas/Src/Core/http/endpoints.dart';
import 'package:agente_vendas_saas/Src/Core/http/http_manager.dart';
import 'package:agente_vendas_saas/Src/Features/followups/domain/followup_rule_input.dart';
import 'package:agente_vendas_saas/Src/Features/followups/domain/followups_repository.dart';
import 'package:agente_vendas_saas/Src/Shared/models/followup_models.dart';

class RemoteFollowUpsRepository implements FollowUpsRepository {
  RemoteFollowUpsRepository(this._httpManager);

  final HttpManager _httpManager;

  @override
  Future<FollowUpsPageResult> list({
    required String workspaceId,
    String? search,
    String? cursor,
    int limit = 30,
  }) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.followupsList,
      parameters: <String, dynamic>{
        'workspaceId': workspaceId,
        if (search?.trim().isNotEmpty == true) 'search': search!.trim(),
        if (cursor != null) 'cursor': cursor,
        'limit': limit,
      },
    );
    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data, :final meta) =>
        FollowUpsPageResult(
          items: _maps(data['items'] ?? data['rules'] ?? data['followups'])
              .map(FollowUpRuleModel.fromJson)
              .toList(growable: false),
          nextCursor: meta.nextCursor ?? data['nextCursor']?.toString(),
          correlationId: meta.correlationId,
        ),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }

  @override
  Future<FollowUpRuleModel> upsert({
    required String workspaceId,
    required FollowUpRuleInput input,
    required String clientRequestId,
    String? followupId,
  }) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.followupsUpsert,
      parameters: <String, dynamic>{
        'workspaceId': workspaceId,
        if (followupId != null) 'followupId': followupId,
        'rule': input.toJson(),
        'clientRequestId': clientRequestId,
      },
    );
    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data) =>
        FollowUpRuleModel.fromJson(_map(data['rule'] ?? data['followup'] ?? data)),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }

  static Map<String, dynamic> _map(dynamic raw) => raw is Map
      ? Map<String, dynamic>.from(raw)
      : const <String, dynamic>{};

  static Iterable<Map<String, dynamic>> _maps(dynamic raw) {
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw.whereType<Map>().map(Map<String, dynamic>.from);
  }
}
