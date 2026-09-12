class Endpoints {
  const Endpoints._();

  static const String login = '/login';
  static const String users = '/users';
  static const String logout = '/logout';
  static const String requestPasswordReset = '/requestPasswordReset';

  static String cloudFunction(String name) => '/functions/$name';

  static const String authMe = 'v1-auth-me';
  static const String workspacesCreate = 'v1-workspaces-create';
  static const String dashboardMetrics = 'v1-dashboard-metrics';

  static const String leadsList = 'v1-leads-list';
  static const String leadsGet = 'v1-leads-get';
  static const String leadsCreate = 'v1-leads-create';
  static const String leadsUpdate = 'v1-leads-update';
  static const String leadsImport = 'v1-leads-import';

  static const String customersList = 'v1-customers-list';
  static const String customersCreate = 'v1-customers-create';
  static const String customersGet = 'v1-customers-get';
  static const String customersUpdate = 'v1-customers-update';

  static const String accountsList = 'v1-accounts-list';
  static const String accountsCreate = 'v1-accounts-create';
  static const String accountsGet = 'v1-accounts-get';
  static const String accountsUpdate = 'v1-accounts-update';

  static const String pipelineList = 'v1-pipeline-list';
  static const String pipelineGet = 'v1-pipeline-get';
  static const String pipelineCreate = 'v1-pipeline-create';
  static const String pipelineUpdate = 'v1-pipeline-update';
  static const String pipelineMove = 'v1-pipeline-move';

  static const String conversationsList = 'v1-conversations-list';
  static const String conversationsGet = 'v1-conversations-get';
  static const String conversationsSendMessage = 'v1-conversations-send-message';
  static const String conversationsAssign = 'v1-conversations-assign';
  static const String conversationsSetMode = 'v1-conversations-set-mode';
  static const String conversationsStart = 'v1-conversations-start';
  static const String agentGet = 'v1-agent-get';
  static const String agentUpdate = 'v1-agent-update';
  static const String agentTestReply = 'v1-agent-test-reply';

  static const String knowledgeList = 'v1-knowledge-list';
  static const String knowledgeCreate = 'v1-knowledge-create';
  static const String knowledgeDelete = 'v1-knowledge-delete';

  static const String followupsList = 'followups.list';
  static const String followupsUpsert = 'followups.upsert';
  static const String tasksList = 'v1-tasks-list';

  static const String integrationsList = 'v1-integrations-list';
  static const String integrationsConnect = 'v1-integrations-connect';
  static const String usageCurrent = 'v1-usage-current';
  static const String teamList = 'v1-team-list';
  static const String teamInvite = 'v1-team-invite';
  static const String teamUpdateRole = 'v1-team-update-role';

  static const String billingCurrent = 'v1-billing-current';
  static const String billingPlans = 'v1-billing-plans';
  static const String billingCheckout = 'v1-billing-checkout';
  static const String billingCancel = 'v1-billing-cancel';

  static const String acquisitionOverview = 'v1-acquisition-overview';
  static const String acquisitionCampaignGet = 'v1-acquisition-campaign-get';
  static const String acquisitionCampaignUpsert = 'v1-acquisition-campaign-upsert';
  static const String acquisitionCampaignPublish = 'v1-acquisition-campaign-publish';
  static const String acquisitionCampaignAction = 'v1-acquisition-campaign-action';
  static const String acquisitionAiSuggest = 'v1-acquisition-ai-suggest';
  static const String acquisitionBindGoogleClick = 'v1-acquisition-attribution-bind-google-click';

  static const String googleAdsConnectionStatus = 'v1-google-ads-connection-status';
  static const String googleAdsOAuthStart = 'v1-google-ads-oauth-start';
  static const String googleAdsAccounts = 'v1-google-ads-accounts';
  static const String googleAdsSelectAccount = 'v1-google-ads-select-account';
  static const String googleAdsDisconnect = 'v1-google-ads-disconnect';

  static const String googleDataManagerStatus = 'v1-google-data-manager-status';
  static const String googleDataManagerOAuthStart = 'v1-google-data-manager-oauth-start';
}
