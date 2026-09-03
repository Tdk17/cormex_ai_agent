# API — Follow-ups

Tela: `/followups`
Funções preservadas: `followups.list` e `followups.upsert`

## `followups.list`

```json
{
  "workspaceId": "ws_01J...",
  "search": "sem resposta",
  "cursor": null,
  "limit": 30
}
```

Response:

```json
{
  "ok": true,
  "data": {
    "items": [
      {
        "id": "followup_01J...",
        "name": "Retomar em uma hora",
        "delayMinutes": 60,
        "condition": "no_reply",
        "active": true,
        "channel": "whatsapp",
        "message": "",
        "maxAttempts": 2,
        "stopOnReply": true,
        "stopOnLost": true,
        "version": 3
      }
    ]
  },
  "meta": { "nextCursor": null, "correlationId": "req_01J..." }
}
```

## `followups.upsert`

```json
{
  "workspaceId": "ws_01J...",
  "followupId": "followup_01J...",
  "rule": {
    "name": "Retomar em uma hora",
    "delayMinutes": 60,
    "condition": "no_reply",
    "active": true,
    "channel": "whatsapp",
    "message": "",
    "maxAttempts": 2,
    "stopOnReply": true,
    "stopOnLost": true,
    "expectedVersion": 3
  },
  "clientRequestId": "followup_1725192000000"
}
```

Sem `followupId`, cria. Com ID, atualiza. `message` vazia significa que a IA redige usando a conversa, configuração do agente e Base de Conhecimento; ainda assim o backend aplica políticas, limites e horário.

Response: `{ "ok": true, "data": { "rule": {} } }` com a regra completa e versão incrementada.

## Execução obrigatória

- agendar por horário do servidor e converter para o fuso do Workspace apenas na interface;
- antes de cada tentativa, verificar se a regra continua ativa, se a conversa está em `auto`, se o cliente respondeu, se a oportunidade virou `won/lost` e se o limite foi atingido;
- cancelar imediatamente quando `stopOnReply=true` ou `stopOnLost=true`;
- deduplicar por `workspaceId + conversationId + ruleId + attempt`;
- registrar resultado `queued`, `sent`, `skipped`, `failed` e o motivo;
- uma resposta humana ou mudança para modo `human` invalida jobs automáticos pendentes.
