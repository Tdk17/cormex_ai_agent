# API — Integrações de canais

Tela: `/integrations`  
Funções genéricas preservadas: `integrations.list` e `integrations.connect`

O front atual do Google Ads usa também `v1-google-ads-connection-status` e `v1-google-ads-oauth-start`, detalhadas em [Google Ads OAuth](google-ads-oauth-api.md). As funções genéricas atendem a tela consolidada de canais e futuras conexões como WhatsApp.

## DTO público `Integration`

```json
{
  "id": "integration_01J...",
  "provider": "whatsapp",
  "type": "messaging",
  "status": "connected",
  "displayName": "WhatsApp Comercial",
  "maskedAccount": "+55 •• •••••-1234",
  "externalAccountId": "sanitized_external_id",
  "capabilities": ["inbound_messages", "outbound_messages", "templates"],
  "lastSyncAt": "2026-09-03T14:00:00.000Z",
  "requiresAction": false,
  "version": 3
}
```

Valores mínimos:

- `provider`: `google_ads`, `whatsapp`, `meta_ads`;
- `type`: `ads`, `messaging`;
- `status`: `disconnected`, `connecting`, `connected`, `authorization_error`, `permission_error`, `payment_issue`, `expired`, `disabled`.

O DTO é sanitizado. Nunca retornar access token, refresh token, client secret, webhook secret, app secret, developer token ou credencial de sistema.

## 1. `integrations.list`

### Request

```json
{
  "workspaceId": "ws_01J...",
  "type": "messaging"
}
```

`type` é opcional.

### Response

```json
{
  "ok": true,
  "data": {
    "items": [
      {
        "id": "integration_01J...",
        "provider": "whatsapp",
        "type": "messaging",
        "status": "connected",
        "displayName": "WhatsApp Comercial",
        "maskedAccount": "+55 •• •••••-1234",
        "capabilities": ["inbound_messages", "outbound_messages"],
        "lastSyncAt": "2026-09-03T14:00:00.000Z",
        "requiresAction": false,
        "version": 3
      }
    ]
  },
  "meta": { "correlationId": "req_01J..." }
}
```

## 2. `integrations.connect`

Função de comando genérica. O campo `action` define a operação.

### Iniciar ou renovar autorização

```json
{
  "workspaceId": "ws_01J...",
  "provider": "whatsapp",
  "action": "start",
  "returnUrl": "https://tdk17.github.io/cormex_ai_agent/integrations",
  "clientRequestId": "integration_1725192000000"
}
```

`action` aceita `start`, `refresh` e `disconnect`. `returnUrl` é obrigatório para fluxos OAuth e deve pertencer à allowlist do backend.

### Response para OAuth/Embedded Signup

```json
{
  "ok": true,
  "data": {
    "status": "authorization_required",
    "authorizationUrl": "https://provider.example.com/oauth/...",
    "expiresAt": "2026-09-03T15:10:00.000Z"
  },
  "meta": { "correlationId": "req_01J..." }
}
```

### Desconectar

```json
{
  "workspaceId": "ws_01J...",
  "provider": "whatsapp",
  "integrationId": "integration_01J...",
  "action": "disconnect",
  "expectedVersion": 3,
  "clientRequestId": "integration_disconnect_1725192000000"
}
```

Response:

```json
{
  "ok": true,
  "data": {
    "integration": {
      "id": "integration_01J...",
      "provider": "whatsapp",
      "status": "disconnected",
      "version": 4
    }
  },
  "meta": { "correlationId": "req_01J..." }
}
```

Desconectar deve:

1. revogar credenciais no provedor quando disponível;
2. marcar credenciais locais como revogadas;
3. parar novos envios e jobs automáticos;
4. preservar mensagens, leads, auditoria e métricas históricas;
5. invalidar webhooks/estados pendentes daquela integração.

## 3. WhatsApp

### Conexão

- usar fluxo oficial do provedor/Meta, sem solicitar senha no CormeX;
- guardar token e app secret somente no backend;
- vincular `phoneNumberId`, WABA/conta e número exibido ao workspace;
- assinar/validar webhooks;
- confirmar permissões de envio, recebimento e templates;
- retornar somente campos mascarados.

### Regras operacionais

- mensagens iniciadas pela empresa devem respeitar janela e templates exigidos pelo canal;
- opt-out interrompe IA, follow-ups e novos envios de marketing;
- cada mensagem externa deve manter `providerMessageId` para deduplicação e status;
- falha/revogação muda a integração para `authorization_error` ou `permission_error`.

Os webhooks e o pipeline de mensagens estão em [Runtime automático](automation-runtime-api.md).

## 4. Google Ads

Para o Google Ads, o contrato especializado é a fonte de verdade:

- `v1-google-ads-connection-status`;
- `v1-google-ads-oauth-start`;
- `GET /oauth/google-ads/callback`;
- `v1-google-ads-accounts`;
- `v1-google-ads-select-account`;
- `v1-google-ads-disconnect`.

`integrations.list` pode agregar o estado sanitizado dessa conexão, mas não substitui as funções de seleção de conta.

## 5. Autorização

| Ação | Papel mínimo |
| --- | --- |
| Listar | `seller` |
| Conectar/renovar | `admin` |
| Selecionar conta de anúncios | `admin` |
| Desconectar | `admin` |

## 6. Persistência

Separar obrigatoriamente:

- `Integration`: estado e metadados públicos sanitizados;
- `IntegrationCredential`: tokens/segredos criptografados, sem CLP/ACL de leitura do cliente;
- `OAuthState`: hash de state, usuário, workspace, return URL, expiração e uso;
- `ProviderWebhookEvent`: hash/ID para deduplicação e auditoria.

## 7. Erros

`UNAUTHENTICATED`, `FORBIDDEN`, `WORKSPACE_NOT_FOUND`, `VALIDATION_ERROR`, `NOT_FOUND`, `CONFLICT`, `RATE_LIMITED`, `INTEGRATION_NOT_CONNECTED`, `AUTHORIZATION_ERROR`, `EXTERNAL_PROVIDER_ERROR`, `INTERNAL_ERROR`.

## 8. Critérios de aceite

- [ ] conexão e desconexão são idempotentes;
- [ ] `returnUrl` usa allowlist;
- [ ] state OAuth é aleatório, curto, expirável e de uso único;
- [ ] nenhum segredo aparece no bundle, response ou log;
- [ ] workspace é recuperado de estado/integração persistida, não de parâmetro público do webhook;
- [ ] revogação para jobs automáticos imediatamente;
- [ ] eventos recebidos são deduplicados;
- [ ] auditoria registra ator, ação, integração e `correlationId`.
