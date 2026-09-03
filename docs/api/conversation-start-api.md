# API — iniciar conversa e ativar a IA

Tela: `/conversations`
Cloud Function: `v1-conversations-start`

Esta função cria ou reutiliza o Lead, cria ou reutiliza uma conversa aberta e inicia o atendimento no modo escolhido. Ela é necessária porque `v1-conversations-send-message` envia apenas para uma conversa que já existe.

## Request

```json
{
  "workspaceId": "ws_01J...",
  "leadId": "lead_01J...",
  "contactName": "Maria Silva",
  "phone": "+5547999999999",
  "email": "maria@empresa.com",
  "channel": "whatsapp",
  "mode": "auto",
  "initialMessage": null,
  "clientRequestId": "flutter_start_1725192000000"
}
```

Regras:

- exigir `leadId`, `phone` ou `email`;
- `channel`: `whatsapp`, `instagram`, `email` ou `webchat`;
- `mode=auto`: o backend carrega o agente ativo, a mensagem inicial e a Base de Conhecimento, cria a primeira `Message` da IA e a entrega pelo adapter do canal;
- `mode=human`: `initialMessage` é obrigatório e a primeira mensagem tem `senderType=human`;
- validar que a integração do canal está conectada antes de criar uma entrega externa;
- não aceitar `workspaceId` de um tenant sem membership ativa.

## Response

```json
{
  "ok": true,
  "data": {
    "conversation": {
      "id": "conversation_01J...",
      "workspaceId": "ws_01J...",
      "lead": { "id": "lead_01J...", "name": "Maria Silva" },
      "channel": "whatsapp",
      "status": "open",
      "agentMode": "auto",
      "lastMessage": {
        "preview": "Olá, Maria...",
        "sentAt": "2026-09-03T14:00:00.000Z"
      },
      "unreadCount": 0,
      "updatedAt": "2026-09-03T14:00:00.000Z"
    }
  },
  "meta": { "correlationId": "req_01J..." }
}
```

## Idempotência e automação

Criar índice único lógico por `workspaceId + clientRequestId`. Repetir a mesma chamada devolve a mesma conversa e nunca envia a primeira mensagem duas vezes.

No modo `auto`, cada mensagem recebida agenda o processamento do agente. O worker deve conferir novamente `Conversation.agentMode`, status, horário, limites e versão imediatamente antes de gerar e imediatamente antes de entregar uma resposta. Uma conversa em `human` nunca pode receber resposta automática.

## Erros esperados

| Código | Uso |
| --- | --- |
| `VALIDATION_ERROR` | contato, canal, modo ou mensagem inválidos |
| `INTEGRATION_NOT_CONNECTED` | canal sem autorização válida |
| `AI_NOT_CONFIGURED` | modo automático sem agente/provedor ativo |
| `FORBIDDEN` | membership sem permissão |
| `CONFLICT` | request id usado com outro payload |
| `RATE_LIMITED` | limite por workspace/contato |
