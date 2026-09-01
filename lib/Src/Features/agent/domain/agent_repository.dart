import 'package:agente_vendas_saas/Src/Features/agent/domain/agent_configuration_input.dart';
import 'package:agente_vendas_saas/Src/Features/agent/domain/agent_test_request.dart';
import 'package:agente_vendas_saas/Src/Shared/models/agent_models.dart';

abstract interface class AgentRepository {
  Future<AgentLoadResult> get({required String workspaceId});

  Future<AgentSaveResult> update({
    required String workspaceId,
    required AgentConfigurationInput input,
  });

  Future<AgentTestResult> testReply({
    required String workspaceId,
    required AgentTestRequest request,
  });
}

class AgentLoadResult {
  const AgentLoadResult({this.agent, this.correlationId});

  final SalesAgentModel? agent;
  final String? correlationId;
}

class AgentSaveResult {
  const AgentSaveResult({required this.agent, this.correlationId});

  final SalesAgentModel agent;
  final String? correlationId;
}

class AgentTestResult {
  const AgentTestResult({
    required this.reply,
    this.correlationId,
    this.usage,
  });

  final AgentTestReplyModel reply;
  final String? correlationId;
  final Map<String, dynamic>? usage;
}
