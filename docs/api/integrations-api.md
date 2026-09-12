# API — Integrações de canais

Tela: `/integrations`  
Funções do aplicativo: `v1-integrations-list` e `v1-integrations-connect`

O front atual do Google Ads usa também `v1-google-ads-connection-status` e `v1-google-ads-oauth-start`, detalhadas em [Google Ads OAuth](google-ads-oauth-api.md). As funções genéricas atendem a tela consolidada de canais.

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
  "capabilities": ["inbound_messages", "outbound_messages"],
  "lastSyncAt": "2026-09-08T13:00:00.000Z",
  "requiresAction": false,
  "version": 3
}
```

Valores mínimos:

- `provider`: `google_ads`, `whatsapp`, `meta_ads`;
- `type`: `ads`, `messaging`;
- `status`: `disconnected`, `connecting`, `connected`, `authorization_error`, `permission_error`, `payment_issue`, `expired`, `disabled`.

O DTO é sanitizado. Nunca retornar access token, refresh token, client secret, webhook secret, app secret, cookie, localStorage, credencial de sessão do WhatsApp Web ou qualquer segredo de sistema.

## 1. `v1-integrations-list`

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
        "lastSyncAt": "2026-09-08T13:00:00.000Z",
        "requiresAction": false,
        "version": 3
      }
    ]
  },
  "meta": { "correlationId": "req_01J..." }
}
```

## 2. `v1-integrations-connect`

Função de comando genérica. O campo `action` define a operação.

### Ações OAuth/Embedded Signup

O WhatsApp usa a integração oficial da Meta e segue as mesmas ações dos demais provedores OAuth:

- `start`;
- `refresh`;
- `disconnect`.

O Flutter não recebe token, app secret ou credenciais da conta. Ele recebe apenas a URL de autorização oficial criada pelo backend.

### Iniciar autorização do WhatsApp

Request:

```json
{
  "workspaceId": "ws_01J...",
  "provider": "whatsapp",
  "action": "start",
  "returnUrl": "https://cormexcrm.com.br/integrations",
  "clientRequestId": "integration_whatsapp_1788872400000"
}
```

Response esperado enquanto aguarda autorização na Meta:

```json
{
  "ok": true,
  "data": {
    "status": "authorization_required",
    "authorizationUrl": "https://www.facebook.com/vXX.X/dialog/oauth?...",
    "expiresAt": "2026-09-08T13:10:00.000Z"
  },
  "meta": { "correlationId": "req_01J..." }
}
```

Depois que o usuário concluir a autorização na Meta e o callback for processado, `v1-integrations-list` deve retornar `status: connected` para aquele workspace.

### Response para OAuth/Embedded Signup

```json
{
  "ok": true,
  "data": {
    "status": "authorization_required",
    "authorizationUrl": "https://provider.example.com/oauth/...",
    "expiresAt": "2026-09-08T14:10:00.000Z"
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
  "clientRequestId": "integration_disconnect_1788872400000"
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

1. revogar a autorização no provedor quando disponível;
2. remover ou invalidar tokens e credenciais locais;
3. parar novos envios e jobs automáticos imediatamente;
4. preservar mensagens, leads, auditoria e métricas históricas;
5. invalidar estados OAuth e operações pendentes daquela integração.

## 3. WhatsApp — arquitetura oficial Meta multi-tenant

### Regra principal

Cada cliente do CormeX conecta **o próprio número**. A integração e sua credencial pertencem a um único `workspaceId`.

Exemplo:

```text
Workspace A -> credencial Meta A -> número do Cliente A
Workspace B -> credencial Meta B -> número do Cliente B
Workspace C -> credencial Meta C -> número do Cliente C
```

Uma credencial nunca pode ser compartilhada entre workspaces.

### Fluxo

1. usuário autenticado abre Integrações;
2. front chama `v1-integrations-connect` com `provider=whatsapp` e `action=start`;
3. backend cria um `OAuthState` curto, aleatório e vinculado ao usuário e workspace;
4. backend devolve a `authorizationUrl` oficial da Meta;
5. front abre essa URL no navegador;
6. usuário autoriza a conta e o número do WhatsApp Business;
7. callback troca o código por token, valida WABA e `phoneNumberId` e assina os webhooks;
8. backend criptografa a credencial em `IntegrationCredential` e grava somente metadados públicos em `Integration`;
9. `v1-integrations-list` passa para `connected`;
10. o motor de conversas passa a usar a credencial daquele workspace para receber e enviar mensagens.

### Requisitos obrigatórios do backend

- isolamento rígido por `workspaceId` e `integrationId`;
- uma chave lógica de integração por workspace e provider;
- nunca enviar access token, app secret ou credenciais ao Flutter;
- criptografar tokens em repouso com chave exclusiva do servidor;
- `OAuthState` aleatório, de uso único e expirável;
- validar `wabaId` e `phoneNumberId` contra a autorização recebida;
- detectar `connected`, `disconnected`, `expired` e `authorization_error`;
- renovar ou revogar credenciais sem criar integração duplicada;
- impedir operações concorrentes sobre a mesma integração;
- rate limit por workspace;
- auditoria de conectar, reconectar e desconectar;
- fila de mensagens por workspace para impedir mistura entre clientes;
- opt-out deve interromper IA, follow-ups e novos envios de marketing;
- cada mensagem externa deve manter `providerMessageId` para deduplicação e status.

### Configuração obrigatória do backend

O Cloud Code anexado exige as variáveis:

- `WHATSAPP_APP_ID`;
- `WHATSAPP_APP_SECRET`;
- `WHATSAPP_CONFIG_ID`;
- `WHATSAPP_GRAPH_VERSION`;
- `WHATSAPP_OAUTH_CALLBACK_URL`;
- `WHATSAPP_RETURN_URL_ALLOWLIST`;
- `INTEGRATION_CREDENTIAL_ENCRYPTION_KEY`.

O callback deve chamar o processamento de `whatsapp.oauth.callback`, validar o `state`, trocar o código por token, consultar WABA/números e concluir a integração.

Os webhooks e o pipeline de mensagens estão em [Runtime automático](automation-runtime-api.md).

## 4. Google Ads

Para o Google Ads, o contrato especializado é a fonte de verdade:

- `v1-google-ads-connection-status`;
- `v1-google-ads-oauth-start`;
- `GET /oauth/google-ads/callback`;
- `v1-google-ads-accounts`;
- `v1-google-ads-select-account`;
- `v1-google-ads-disconnect`.

`v1-integrations-list` pode agregar o estado sanitizado dessa conexão, mas não substitui as funções de seleção de conta.

## 5. Autorização

| Ação | Papel mínimo |
| --- | --- |
| Listar | `seller` |
| Conectar/renovar | `admin` |
| Desconectar | `admin` |

## 6. Persistência

Separar obrigatoriamente:

- `Integration`: estado e metadados públicos sanitizados;
- `IntegrationCredential`: tokens criptografados e sem CLP/ACL de leitura do cliente;
- `OAuthState`: hash do state, workspace, usuário, expiração e uso;
- `ProviderWebhookEvent`: hash/ID para deduplicação e auditoria.

## 7. Erros

`UNAUTHENTICATED`, `FORBIDDEN`, `WORKSPACE_NOT_FOUND`, `VALIDATION_ERROR`, `NOT_FOUND`, `CONFLICT`, `RATE_LIMITED`, `INTEGRATION_NOT_CONNECTED`, `AUTHORIZATION_ERROR`, `EXTERNAL_PROVIDER_ERROR`, `INTERNAL_ERROR`.

## 8. Critérios de aceite

- [ ] cada workspace possui sua própria integração e credencial WhatsApp;
- [ ] um workspace nunca consegue consultar credenciais de outro;
- [ ] `start`, `refresh` e `disconnect` são idempotentes;
- [ ] `OAuthState` expira rapidamente e é de uso único;
- [ ] o retorno OAuth valida WABA e `phoneNumberId` autorizados;
- [ ] a credencial é recuperada com segurança após reinício do worker;
- [ ] nenhum token, app secret ou segredo aparece no bundle, response ou log;
- [ ] revogação para jobs automáticos imediatamente;
- [ ] eventos recebidos são deduplicados;
- [ ] mensagens e filas sempre carregam `workspaceId`/`integrationId` internamente;
- [ ] auditoria registra ator, ação, integração e `correlationId`;
- [ ] CRM, IA e pipeline dependem do contrato de integração, sem acessar diretamente os tokens da Meta.
