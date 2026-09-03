# API interna — Automação, webhooks e workers

Este documento define o backend que faz o CormeX trabalhar sem a tela aberta: receber leads, abrir conversas, pedir resposta à IA, enviar mensagens, executar follow-ups e atualizar métricas.

Nenhuma rota desta página é chamada diretamente pelo Flutter.

## 1. Fluxo obrigatório

1. provedor entrega lead ou mensagem por webhook;
2. backend valida autenticidade e deduplica;
3. backend resolve a integração e o workspace sem confiar em `workspaceId` público;
4. cria ou atualiza `Lead` com atribuição de origem;
5. cria ou atualiza `Conversation`;
6. verifica campanha, modo do agente, canal, consentimento, opt-out, horário e plano;
7. enfileira resposta da IA ou tarefa humana;
8. envia pelo worker do canal;
9. recebe status `sent`, `delivered`, `read` ou `failed`;
10. atualiza Pipeline, Follow-ups, Tarefas, Uso e Dashboard.

Persistir o evento e enfileirar o trabalho antes de responder sucesso ao provedor. Não executar geração de IA ou envio completo dentro da requisição do webhook.

## 2. Webhook de lead do Google Ads

Rota recomendada:

```http
POST /webhooks/google-ads/leads/{publicIntegrationId}
Content-Type: application/json
```

`publicIntegrationId` é um identificador aleatório e revogável, não o `workspaceId` nem o ID interno da credencial.

### Payload do Google

```json
{
  "lead_id": "google-lead-unique-id",
  "api_version": "1.0",
  "form_id": 1234567890,
  "campaign_id": 9876543210,
  "google_key": "configured-secret-key",
  "is_test": false,
  "gcl_id": "google-click-id",
  "adgroup_id": 5555555555,
  "creative_id": 6666666666,
  "asset_group_id": 7777777777,
  "lead_stage": "SUBMITTED",
  "lead_submit_time": "2026-09-03T14:00:00Z",
  "lead_source": "LEAD_FORM",
  "user_column_data": [
    {
      "column_id": "FULL_NAME",
      "string_value": "Maria Souza"
    },
    {
      "column_id": "EMAIL",
      "string_value": "maria@example.com"
    },
    {
      "column_id": "PHONE_NUMBER",
      "string_value": "+5511999999999"
    }
  ]
}
```

Campos desconhecidos devem ser ignorados para compatibilidade futura. Usar `column_id`, não `column_name`, como identificador estável.

### Validação

- localizar a integração ativa pelo `publicIntegrationId`;
- comparar `google_key` com o segredo armazenado usando comparação resistente a timing;
- confirmar que `campaign_id`/`form_id` pertence a campanha publicada pelo workspace ou a uma allowlist vinculada;
- validar `lead_id`, JSON, tamanho e tipos;
- deduplicar por `provider=google_ads + integrationId + lead_id`;
- tratar `is_test=true` como teste, sem contaminar métricas ou iniciar contato real;
- nunca aceitar `workspaceId` do payload como fonte de autorização.

### Mapeamento para `Lead`

```json
{
  "workspaceId": "resolved_server_side",
  "name": "Maria Souza",
  "email": "maria@example.com",
  "phone": "+5511999999999",
  "source": "google_ads",
  "sourceDetails": {
    "leadId": "google-lead-unique-id",
    "gclid": "google-click-id",
    "campaignId": "9876543210",
    "adGroupId": "5555555555",
    "creativeId": "6666666666",
    "formId": "1234567890",
    "leadSource": "LEAD_FORM",
    "submittedAt": "2026-09-03T14:00:00Z"
  },
  "customFields": {}
}
```

Campos adicionais de `user_column_data` entram em `customFields` por allowlist e com limite de tamanho.

### Respostas HTTP

| Status | Body | Significado |
| --- | --- | --- |
| `200` | `{}` | Evento persistido ou duplicado já processado |
| `400` | `{"message":"invalid payload"}` | Erro definitivo de formato |
| `401` | `{"message":"invalid key"}` | `google_key` inválida |
| `404` | `{"message":"integration not found"}` | Identificador revogado/ausente |
| `500`/`503` | `{"message":"temporary failure"}` | Falha temporária; provedor pode repetir |

O Google informa que uma entrega pode ocorrer mais de uma vez; `lead_id` é a chave de deduplicação obrigatória.

Referências oficiais:

- [Google Ads Lead Form Webhook — visão geral](https://developers.google.com/google-ads/webhook/docs/overview)
- [Google Ads Lead Form Webhook — implementação](https://developers.google.com/google-ads/webhook/docs/implementation)

## 3. Webhook do WhatsApp

Rotas recomendadas:

```http
GET /webhooks/whatsapp
POST /webhooks/whatsapp
```

### Verificação `GET`

Validar o token de verificação configurado no backend e devolver apenas o challenge quando válido. Não usar o token como segredo de envio nem devolvê-lo em logs.

### Eventos `POST`

O parser deve aceitar a estrutura oficial do provedor e normalizar cada item em um evento interno. Processar:

- mensagens recebidas;
- status de mensagens enviadas;
- erros de entrega;
- alterações de template/número apenas quando necessárias.

Validar a assinatura do corpo bruto com o segredo do app/provedor antes do parse de negócio. Resolver o workspace por `phoneNumberId`/integração persistida.

### Evento interno de mensagem recebida

```json
{
  "eventId": "provider-event-or-hash",
  "provider": "whatsapp",
  "providerMessageId": "wamid...",
  "integrationId": "integration_01J...",
  "workspaceId": "ws_01J...",
  "from": "+5511999999999",
  "to": "+5511888888888",
  "type": "text",
  "content": "Quero saber o preço",
  "media": null,
  "sentAt": "2026-09-03T14:02:00.000Z"
}
```

Deduplicar por `provider + providerMessageId`. Criar/atualizar Lead e Conversation no mesmo workspace. Uma mensagem do cliente:

- zera contador de follow-up sem resposta;
- cancela jobs pendentes quando `stopOnReply=true`;
- atualiza `lastMessageAt` e não lidas;
- pode enfileirar IA somente em modo `auto` e com agente ativo;
- nunca autoriza a IA a responder se houver opt-out ou bloqueio.

Referências oficiais:

- [WhatsApp Business Platform — webhooks](https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview)
- [WhatsApp messages webhook](https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/reference/messages)

## 4. `v1-conversations-delivery-webhook`

Função interna acionada pelo adaptador do canal depois que o payload externo foi autenticado e normalizado.

### Request interno

```json
{
  "eventId": "evt_provider_01J...",
  "workspaceId": "ws_01J...",
  "integrationId": "integration_01J...",
  "provider": "whatsapp",
  "providerMessageId": "wamid...",
  "messageId": "message_01J...",
  "status": "delivered",
  "occurredAt": "2026-09-03T14:03:00.000Z",
  "failure": null
}
```

Status: `queued`, `sent`, `delivered`, `read`, `failed`.

Em falha:

```json
{
  "failure": {
    "providerCode": "masked_code",
    "category": "temporary",
    "retryable": true,
    "safeMessage": "O canal não confirmou a entrega."
  }
}
```

### Autorização

- não aceitar chamada direta com sessão Flutter;
- exigir credencial de serviço, assinatura/HMAC ou invocação privada;
- validar integração e mensagem no mesmo workspace;
- deduplicar por `eventId`;
- atualizações são monotônicas: `read` não volta para `sent`;
- `failed` não sobrescreve `read`.

Response interno: `{ "ok": true, "data": { "accepted": true } }`.

## 5. Worker `knowledge.process`

Payload da fila:

```json
{
  "jobId": "job_01J...",
  "workspaceId": "ws_01J...",
  "sourceId": "source_01J...",
  "sourceVersion": 1
}
```

Etapas:

1. carregar fonte ainda `processing`;
2. buscar arquivo somente de host permitido ou usar conteúdo persistido;
3. extrair texto com limites de página, tamanho e tempo;
4. sanitizar e dividir em chunks;
5. gerar embeddings quando configurado;
6. gravar chunks com `workspaceId` e `sourceId`;
7. marcar fonte `ready`, `contentCount` e versão;
8. em falha, marcar `failed` com mensagem segura;
9. contabilizar storage/IA de forma idempotente.

Reprocessamento deve apagar/substituir chunks da versão anterior atomicamente. Nunca pesquisar ou gerar embeddings sem filtro de workspace.

## 6. Worker `conversations.ai-reply`

Payload da fila:

```json
{
  "jobId": "job_01J...",
  "workspaceId": "ws_01J...",
  "conversationId": "conversation_01J...",
  "triggerMessageId": "message_01J...",
  "agentVersion": 7
}
```

Antes de chamar a IA:

- conversation ainda existe e está em `auto`;
- agente está ativo;
- mensagem gatilho continua sendo a última mensagem relevante do cliente;
- não há resposta humana posterior;
- canal está conectado;
- cliente não pediu para parar;
- horário e políticas permitem resposta;
- limite do plano está disponível;
- conhecimento usado pertence ao workspace e está `ready`.

Saída interna esperada:

```json
{
  "content": "Mensagem que será enviada ao cliente.",
  "action": "reply",
  "confidence": 0.91,
  "handoff": false,
  "handoffReason": null,
  "qualification": {
    "score": 78,
    "fields": { "budget": "até 500" }
  },
  "pipelineAction": null,
  "followupAction": "schedule"
}
```

Valores de `action`: `reply`, `ask`, `handoff`, `no_action`. O backend valida e reduz essa saída para ações permitidas; nunca executar instrução arbitrária devolvida pelo modelo.

### Handoff obrigatório

Suspender resposta automática e criar/atribuir tarefa humana quando ocorrer:

- pedido explícito por humano;
- cobrança, disputa, ameaça, conteúdo sensível ou tema fora da política;
- baixa confiança;
- ação financeira não autorizada;
- tentativa excedida;
- modo `assist` ou `human`.

Em modo `assist`, a IA pode produzir `suggestedReply`, mas não envia ao canal.

## 7. Worker de envio outbound

Entrada:

```json
{
  "jobId": "job_01J...",
  "workspaceId": "ws_01J...",
  "messageId": "message_01J...",
  "integrationId": "integration_01J...",
  "attempt": 1
}
```

O worker deve:

1. adquirir lock idempotente por `messageId`;
2. validar conexão, opt-out, modo e política do canal;
3. usar template aprovado quando a conversa iniciada pela empresa exigir;
4. enviar ao provedor;
5. persistir `providerMessageId` e status `sent`/`failed`;
6. aplicar retry exponencial apenas para falhas temporárias;
7. nunca reenviar se já houver confirmação do provedor.

## 8. Worker `followups.dispatch`

Executado em agenda recorrente com lock distribuído. Para cada execução vencida:

- regra continua ativa e pertence ao workspace;
- conversa está em `auto`;
- `stopOnReply`/`stopOnLost` ainda permitem;
- oportunidade não está `won` ou `lost`;
- cliente não optou por sair;
- canal está conectado;
- tentativa é menor ou igual a `maxAttempts`;
- horário do workspace permite envio;
- deduplicação por `workspaceId + conversationId + ruleId + attempt`.

Resultados: `queued`, `sent`, `skipped`, `failed`. Persistir motivo seguro em `FollowUpExecution`.

## 9. Worker `acquisition.metrics-sync`

Entrada:

```json
{
  "jobId": "job_01J...",
  "workspaceId": "ws_01J...",
  "integrationId": "integration_01J...",
  "provider": "google_ads",
  "from": "2026-09-02T00:00:00.000Z",
  "to": "2026-09-03T00:00:00.000Z"
}
```

Buscar métricas por IDs externos salvos em `providerCampaignIds`, normalizar para `AdCampaignDailyMetric` e recalcular visão agregada. Nunca misturar moeda sem conversão explícita. Sincronização repetida do mesmo período deve substituir/upsert, não somar novamente.

## 10. Eventos internos mínimos

| Evento | Chave de deduplicação | Consumidores |
| --- | --- | --- |
| `lead.received` | provedor + lead externo | Lead, Conversation, Pipeline, Uso |
| `message.inbound` | provedor + mensagem externa | Conversation, IA, Follow-up |
| `message.outbound.queued` | messageId | Worker do canal |
| `message.status.changed` | eventId | Conversation, Dashboard |
| `conversation.handoff` | conversationId + version | Tarefa, notificação |
| `opportunity.changed` | opportunityId + version | Follow-up, Dashboard, Ads attribution |
| `campaign.published` | campanha + version | Métricas, auditoria |
| `knowledge.created` | sourceId + version | Processamento |

Use outbox transacional ou mecanismo equivalente: a mutação de negócio e o registro do evento precisam ser confirmados juntos.

## 11. Observabilidade

Todo evento/job deve registrar:

- `correlationId`, `eventId`/`jobId`;
- workspace e recurso por ID interno;
- provedor e operação;
- tentativa, latência, resultado e categoria de erro;
- IDs externos mascarados quando necessário.

Não registrar conteúdo integral de mensagens, tokens, secrets, `google_key`, código OAuth ou PII não necessária.

## 12. Critérios de aceite ponta a ponta

- [ ] lead de teste do Google retorna 200 e aparece marcado como teste, sem mensagem real;
- [ ] lead real cria um único Lead em retries;
- [ ] workspace é resolvido pelo vínculo da integração;
- [ ] conversa nasce com origem/campanha preservadas;
- [ ] modo `auto` gera e envia; `assist` apenas sugere; `human` não chama IA;
- [ ] status do canal atualiza a mensagem de forma monotônica;
- [ ] resposta do cliente cancela follow-up quando configurado;
- [ ] venda/perda interrompe automação incompatível;
- [ ] opt-out impede novos envios;
- [ ] falha externa mantém retry seguro sem duplicidade;
- [ ] troca de tenant nunca reutiliza credencial, contexto, fila ou conhecimento;
- [ ] Dashboard reflete os eventos após processamento eventual.
