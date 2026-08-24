class Endpoints {
  const Endpoints._();

  static const String login = '/login';
  static const String users = '/users';
  static const String logout = '/logout';
  static const String requestPasswordReset = '/requestPasswordReset';

  static String cloudFunction(String name) => '/functions/$name';

  static const String authMe = 'auth.me';
  static const String workspacesCreate = 'v1-workspaces-create';
  static const String dashboardMetrics = 'dashboard.metrics';
  static const String leadsList = 'leads.list';
  static const String leadsGet = 'leads.get';
  static const String leadsCreate = 'leads.create';
  static const String leadsUpdate = 'leads.update';
  static const String leadsImport = 'leads.import';
  static const String pipelineList = 'pipeline.list';
  static const String pipelineGet = 'pipeline.get';
  static const String pipelineCreate = 'pipeline.create';
  static const String pipelineUpdate = 'pipeline.update';
  static const String pipelineMove = 'pipeline.move';
  static const String conversationsList = 'conversations.list';
  static const String conversationsGet = 'conversations.get';
  static const String conversationsSendMessage = 'conversations.sendMessage';
  static const String conversationsAssign = 'conversations.assign';
  static const String conversationsSetMode = 'conversations.setMode';
  static const String agentGet = 'agent.get';
  static const String agentUpdate = 'agent.update';
  static const String agentTestReply = 'agent.testReply';
  static const String knowledgeList = 'knowledge.list';
  static const String knowledgeCreate = 'knowledge.create';
  static const String knowledgeDelete = 'knowledge.delete';
  static const String followupsList = 'followups.list';
  static const String followupsUpsert = 'followups.upsert';
  static const String tasksList = 'tasks.list';
  static const String integrationsList = 'integrations.list';
  static const String integrationsConnect = 'integrations.connect';
  static const String usageCurrent = 'usage.current';
  static const String teamList = 'team.list';
  static const String teamInvite = 'team.invite';
  static const String teamUpdateRole = 'team.updateRole';
}
