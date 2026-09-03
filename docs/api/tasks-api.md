# API — Tarefas

Tela planejada: `/tasks`  
Função nominal preservada: `tasks.list`

Tarefas são ações operacionais criadas pelo sistema, pela IA ou por um atendente. A primeira versão do front precisa apenas listar a fila; criação e mudança de estado podem ocorrer por workers internos até que novos contratos sejam versionados.

## DTO `Task`

```json
{
  "id": "task_01J...",
  "title": "Ligar para Maria",
  "description": "Confirmar condição de pagamento.",
  "status": "pending",
  "priority": "high",
  "dueAt": "2026-09-04T15:00:00.000Z",
  "leadId": "lead_01J...",
  "conversationId": "conversation_01J...",
  "opportunityId": "opportunity_01J...",
  "ownerId": "user_01J...",
  "createdBy": "ai",
  "createdAt": "2026-09-03T15:00:00.000Z",
  "updatedAt": "2026-09-03T15:00:00.000Z"
}
```

Enums:

- `status`: `pending`, `in_progress`, `completed`, `cancelled`, `overdue`;
- `priority`: `low`, `normal`, `high`, `urgent`;
- `createdBy`: `user`, `ai`, `followup`, `system`.

Os campos mínimos já esperados pelo model compartilhado são `id`, `title`, `status`, `dueAt`, `leadId` e `ownerId`.

## `tasks.list`

### Request

```json
{
  "workspaceId": "ws_01J...",
  "status": "pending",
  "ownerId": "user_01J...",
  "priority": "high",
  "dueFrom": "2026-09-03T00:00:00.000Z",
  "dueTo": "2026-09-10T23:59:59.999Z",
  "search": "ligar",
  "cursor": null,
  "limit": 30
}
```

Todos os filtros, exceto `workspaceId`, são opcionais. `limit` deve ficar entre 1 e 100.

### Response

```json
{
  "ok": true,
  "data": {
    "items": [
      {
        "id": "task_01J...",
        "title": "Ligar para Maria",
        "status": "pending",
        "dueAt": "2026-09-04T15:00:00.000Z",
        "leadId": "lead_01J...",
        "ownerId": "user_01J..."
      }
    ],
    "owners": [
      { "id": "user_01J...", "name": "Ana Souza" }
    ]
  },
  "meta": {
    "nextCursor": null,
    "correlationId": "req_01J..."
  }
}
```

Ordenação padrão: `dueAt ASC`, depois `id ASC`. A API pode calcular `overdue` na resposta quando uma tarefa pendente ultrapassou o prazo, sem exigir mutação imediata do registro.

## Regras do backend

- validar membership no workspace;
- `seller` vê tarefas próprias e tarefas sem responsável; `owner/admin` podem ver todas;
- sempre validar que lead, conversa, oportunidade e responsável pertencem ao mesmo workspace;
- uma tarefa automática deve indicar a execução/regra que a criou;
- cancelar ou concluir tarefas redundantes quando a oportunidade virar `won` ou `lost`;
- não expor notas privadas de outro vendedor sem permissão;
- indexar `workspaceId + status + dueAt` e `workspaceId + ownerId + dueAt`.

## Extensões futuras

Para criar, editar, concluir, cancelar ou reatribuir pela tela, definir novos nomes versionados e adicioná-los a `Endpoints` no mesmo merge do Flutter. Não sobrecarregar `tasks.list` com mutações.

## Erros

`UNAUTHENTICATED`, `FORBIDDEN`, `WORKSPACE_NOT_FOUND`, `VALIDATION_ERROR`, `NOT_FOUND`, `RATE_LIMITED`, `INTERNAL_ERROR`.
