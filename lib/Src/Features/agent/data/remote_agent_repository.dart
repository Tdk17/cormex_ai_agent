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
        ...input.toJson(),
      },
    );
    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data, :final meta) =>
        AgentSaveResult(
          agent: _agentFromSave(data, workspaceId, input),
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

  static SalesAgentModel _agentFromSave(
    Map<String, dynamic> data,
    String workspaceId,
    AgentConfigurationInput input,
  ) {
    final server = _requiredMap(data, 'agent');

    final normalized = <String, dynamic>{
      'workspaceId': workspaceId,
      'name': input.name,
      'objective': input.objective,
      'persona': input.persona,
      'tone': input.tone,
      'mode': input.mode,
      'productOffer': input.productOffer,
      'initialMessage': input.initialMessage,
      'isActive': input.isActive,
      'rules': input.rules,
      'qualificationQuestions': input.qualificationQuestions,
      'schedule': input.schedule.toJson(),
      'policies': input.policies.toJson(),
      ...server,
    };

    // O backend legado responde active/greeting. Normalizamos para o contrato
    // atual antes de hidratar a interface, sem apagar o que acabou de ser salvo.
    if (!server.containsKey('initialMessage')) {
      final greeting = server['greeting']?.toString().trim();
      normalized['initialMessage'] =
          greeting?.isNotEmpty == true ? greeting : input.initialMessage;
    }
    if (!server.containsKey('isActive')) {
      normalized['isActive'] = server.containsKey('active')
          ? server['active']
          : input.isActive;
    }

    return SalesAgentModel.fromJson(normalized);
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
