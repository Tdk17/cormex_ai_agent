import 'package:agente_vendas_saas/Src/Core/api/api_result.dart';
import 'package:agente_vendas_saas/Src/Core/http/endpoints.dart';
import 'package:agente_vendas_saas/Src/Core/http/http_manager.dart';
import 'package:agente_vendas_saas/Src/Features/pipeline/domain/opportunity_input.dart';
import 'package:agente_vendas_saas/Src/Features/pipeline/domain/pipeline_board.dart';
import 'package:agente_vendas_saas/Src/Features/pipeline/domain/pipeline_repository.dart';
import 'package:agente_vendas_saas/Src/Shared/models/pipeline_models.dart';

class RemotePipelineRepository implements PipelineRepository {
  RemotePipelineRepository(this._httpManager);

  final HttpManager _httpManager;

  @override
  Future<PipelineBoard> list({required String workspaceId}) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.pipelineList,
      parameters: <String, dynamic>{'workspaceId': workspaceId},
    );
    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data, :final meta) => PipelineBoard(
          stages: _maps(data['stages'])
              .map(PipelineStageModel.fromJson)
              .toList(growable: false)
            ..sort(
              (PipelineStageModel first, PipelineStageModel second) =>
                  first.position.compareTo(second.position),
            ),
          opportunities: _maps(data['opportunities'] ?? data['items'])
              .map(OpportunityModel.fromJson)
              .toList(growable: false),
          owners: _maps(data['owners'])
              .map(PipelineOwnerModel.fromJson)
              .where(
                (PipelineOwnerModel item) =>
                    item.id.isNotEmpty && item.name.isNotEmpty,
              )
              .toList(growable: false),
          correlationId: meta.correlationId,
        ),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }

  @override
  Future<OpportunityModel> get({
    required String workspaceId,
    required String opportunityId,
  }) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.pipelineGet,
      parameters: <String, dynamic>{
        'workspaceId': workspaceId,
        'opportunityId': opportunityId,
      },
    );
    return _opportunity(result);
  }

  @override
  Future<OpportunityModel> create({
    required String workspaceId,
    required OpportunityInput input,
  }) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.pipelineCreate,
      parameters: <String, dynamic>{
        'workspaceId': workspaceId,
        'opportunity': input.toJson(),
      },
    );
    return _opportunity(result);
  }

  @override
  Future<OpportunityModel> update({
    required String workspaceId,
    required String opportunityId,
    required OpportunityInput input,
  }) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.pipelineUpdate,
      parameters: <String, dynamic>{
        'workspaceId': workspaceId,
        'opportunityId': opportunityId,
        'changes': input.toJson(),
      },
    );
    return _opportunity(result);
  }

  @override
  Future<OpportunityModel> move({
    required String workspaceId,
    required String opportunityId,
    required String fromStageId,
    required String toStageId,
    required String outcome,
  }) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.pipelineMove,
      parameters: <String, dynamic>{
        'workspaceId': workspaceId,
        'opportunityId': opportunityId,
        'fromStageId': fromStageId,
        'toStageId': toStageId,
        'outcome': outcome,
      },
    );
    return _opportunity(result);
  }

  static OpportunityModel _opportunity(
    ApiResult<Map<String, dynamic>> result,
  ) {
    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data) => OpportunityModel.fromJson(
          data['opportunity'] is Map
              ? Map<String, dynamic>.from(data['opportunity'] as Map)
              : data,
        ),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }

  static Iterable<Map<String, dynamic>> _maps(dynamic raw) {
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw.whereType<Map>().map(Map<String, dynamic>.from);
  }
}
