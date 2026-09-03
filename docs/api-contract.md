# Contrato API — Agente de Vendas SaaS

Este arquivo versiona a fronteira entre Flutter e Cloud Code. Nomes de função, campos de DTO e códigos de erro não devem ser alterados unilateralmente.

## Transporte

As funções lógicas são chamadas por `POST /functions/<nome>` no Parse Server. O método semântico documenta a intenção da operação. A sessão segue no header `X-Parse-Session-Token`; o workspace é enviado somente quando não puder ser inferido, e deve ser validado pelo backend.

## Envelope de sucesso

```json
{
  "ok": true,
  "data": {},
  "meta": {
    "correlationId": "req_xxx",
    "nextCursor": null
  }
}
```

## Envelope de erro

```json
{
  "ok": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Dados inválidos",
    "correlationId": "req_xxx",
    "details": {}
  }
}
```

## Funções estáveis do MVP

| Domínio | Funções |
| --- | --- |
| Sessão e workspace | `v1-auth-me`, `v1-workspaces-create` |
| Dashboard | `v1-dashboard-metrics` |
| Leads | `v1-leads-list`, `v1-leads-get`, `v1-leads-create`, `v1-leads-update`, `v1-leads-import` |
| Pipeline | `v1-pipeline-list`, `v1-pipeline-get`, `v1-pipeline-create`, `v1-pipeline-update`, `v1-pipeline-move` |
| Conversas | `v1-conversations-list`, `v1-conversations-get`, `v1-conversations-send-message`, `v1-conversations-assign`, `v1-conversations-set-mode`, `v1-conversations-start` |
| Agente | `v1-agent-get`, `v1-agent-update`, `v1-agent-test-reply` |
| Central de Aquisição | `v1-acquisition-overview`, `v1-acquisition-campaign-get`, `v1-acquisition-campaign-upsert`, `v1-acquisition-campaign-publish`, `v1-acquisition-campaign-action`, `v1-acquisition-ai-suggest` |
| Google Ads | `v1-google-ads-connection-status`, `v1-google-ads-oauth-start` |
| Conhecimento | `knowledge.list`, `knowledge.create`, `knowledge.delete` |
| Follow-ups e tarefas | `followups.list`, `followups.upsert`, `tasks.list` |
| Integrações | `integrations.list`, `integrations.connect` |
| SaaS | `usage.current`, `v1-team-list`, `v1-team-invite`, `v1-team-update-role` |

## Contratos detalhados por módulo

- [Guia mestre para implementar todo o backend](backend-api-implementation-guide.md)
- [Upload de imagens e documentos pelo Parse Files](api/uploads-api.md)
- [Login, sessão e recuperação de senha](api/login-api.md)
- [Cadastro da conta e criação única da empresa](api/register-company-api.md)
- [Dashboard — métricas, funil e conversas recentes](api/dashboard-api.md)
- [Leads — requests, responses, paginação, importação e checklist do backend](leads-api.md)
- [Pipeline de Vendas — Kanban, resumo e movimentação](api/pipeline-board-api.md)
- [Nova e Editar Oportunidade — leads, criação e atualização](api/opportunity-form-api.md)
- [Detalhes da Oportunidade](api/opportunity-detail-api.md)
- [Caixa de Entrada de Conversas](api/conversations-inbox-api.md)
- [Atendimento da Conversa](api/conversation-thread-api.md)
- [Iniciar conversa manual ou com IA](api/conversation-start-api.md)
- [Configuração do Agente de IA](api/agent-settings-api.md)
- [Console de Teste do Agente](api/agent-test-console-api.md)
- [Central de Aquisição — campanhas, wizard, publicação e IA](api/acquisition-api.md)
- [Google Ads — OAuth, contas, seleção e desconexão](api/google-ads-oauth-api.md)
- [Base de Conhecimento](api/knowledge-api.md)
- [Follow-ups](api/followups-api.md)
- [Tarefas](api/tasks-api.md)
- [Equipe e papéis](api/team-api.md)
- [Integrações de canais](api/integrations-api.md)
- [Plano e uso](api/usage-api.md)
- [Configurações da empresa](api/settings-api.md)
- [Webhooks, workers e runtime automático](api/automation-runtime-api.md)
- [Automação comercial do anúncio à venda](api/sales-automation-flow.md)

## Códigos mínimos

`UNAUTHENTICATED`, `FORBIDDEN`, `WORKSPACE_NOT_FOUND`, `VALIDATION_ERROR`, `NOT_FOUND`, `CONFLICT`, `PLAN_LIMIT_REACHED`, `RATE_LIMITED`, `INTEGRATION_NOT_CONNECTED`, `AI_NOT_CONFIGURED`, `AI_PROVIDER_ERROR`, `AI_INVALID_RESPONSE`, `EXTERNAL_PROVIDER_ERROR`, `INTERNAL_ERROR`.
