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
| Sessão e workspace | `auth.me`, `workspaces.create` |
| Dashboard | `dashboard.metrics` |
| Leads | `leads.list`, `leads.get`, `leads.create`, `leads.update`, `leads.import` |
| Pipeline | `pipeline.list`, `pipeline.move` |
| Conversas | `conversations.list`, `conversations.get`, `conversations.sendMessage`, `conversations.assign`, `conversations.setMode` |
| Agente | `agent.get`, `agent.update`, `agent.testReply` |
| Conhecimento | `knowledge.list`, `knowledge.create`, `knowledge.delete` |
| Follow-ups e tarefas | `followups.list`, `followups.upsert`, `tasks.list` |
| Integrações | `integrations.list`, `integrations.connect` |
| SaaS | `usage.current`, `team.list`, `team.invite`, `team.updateRole` |

## Códigos mínimos

`UNAUTHENTICATED`, `FORBIDDEN`, `WORKSPACE_NOT_FOUND`, `VALIDATION_ERROR`, `NOT_FOUND`, `CONFLICT`, `PLAN_LIMIT_REACHED`, `RATE_LIMITED`, `INTEGRATION_NOT_CONNECTED`, `AI_PROVIDER_ERROR`, `EXTERNAL_PROVIDER_ERROR`, `INTERNAL_ERROR`.
