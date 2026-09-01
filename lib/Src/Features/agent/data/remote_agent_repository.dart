import 'package:agente_vendas_saas/Src/Core/api/api_exception.dart';
import 'package:agente_vendas_saas/Src/Core/api/api_result.dart';
import 'package:agente_vendas_saas/Src/Core/http/endpoints.dart';
import 'package:agente_vendas_saas/Src/Core/http/http_manager.dart';
import 'package:agente_vendas_saas/Src/Features/agent/domain/agent_configuration_input.dart';
import 'package:agente_vendas_saas/Src/Features/agent/domain/agent_repository.dart';
import 'package:agente_vendas_saas/Src/Features/agent/domain/agent_test_request.dart';
import 'package:agente_vendas_saas/Src/Shared/models/agent_models.dart';

class RemoteAgentRepository implements AgentRepository {
  RemoteAgentRepository(this._httpManager);

  final HttpManager _httpManager;

  @override
  Future<AgentLoadResult> get({required String workspaceId}) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.agentGet,
      parameters: <String, dynamic>{'workspaceId': workspaceId},
    );
    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data, :final meta) =>
        AgentLoadResult(
          agent: _agent(data),
          correlationId: meta.correlationId,
        ),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }

  @override
  Future<AgentSaveResult> update({
    required String workspaceId,
    required AgentConfigurationInput input,
  }) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.agentUpdate,
      parameters: <String, dynamic>{
        'workspaceId': workspaceId,
        'config': input.toJson(),
      },
    );
    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data, :final meta) =>
        AgentSaveResult(
          agent: SalesAgentModel.fromJson(_requiredMap(data, 'agent')),
          correlationId: meta.correlationId,
        ),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }

  @override
  Future<AgentTestResult> testReply({
    required String workspaceId,
    required AgentTestRequest request,
  }) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.agentTestReply,
      parameters: <String, dynamic>{
        'workspaceId': workspaceId,
        ...request.toJson(),
      },
    );
    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data, :final meta) =>
        _testResult(data, meta),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }

  static AgentTestResult _testResult(
    Map<String, dynamic> data,
    ApiMeta meta,
  ) {
    final reply = AgentTestReplyModel.fromJson(_requiredMap(data, 'reply'));
    if (reply.content.trim().isEmpty) {
      throw ApiException(
        code: 'INTERNAL_ERROR',
        message: 'A API retornou uma resposta de teste vazia.',
        correlationId: meta.correlationId,
      );
    }
    return AgentTestResult(
      reply: reply,
      correlationId: meta.correlationId,
      usage: _optionalMap(data['usage']),
    );
  }

  static Map<String, dynamic>? _optionalMap(dynamic raw) {
    return raw is Map ? Map<String, dynamic>.from(raw) : null;
  }

  static SalesAgentModel? _agent(Map<String, dynamic> data) {
    final value = _optionalMap(data['agent']);
    return value == null ? null : SalesAgentModel.fromJson(value);
  }

  static Map<String, dynamic> _requiredMap(
    Map<String, dynamic> data,
    String key,
  ) {
    final value = _optionalMap(data[key]);
    if (value != null) return value;
    throw ApiException(
      code: 'INTERNAL_ERROR',
      message: 'A API não retornou o campo obrigatório "$key".',
    );
  }
}
