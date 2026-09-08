# API — Integrações de canais

Tela: `/integrations`  
Funções genéricas preservadas: `integrations.list` e `integrations.connect`

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
        "lastSyncAt": "2026-09-08T13:00:00.000Z",
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

### Ações genéricas OAuth

Para provedores oficiais que usam OAuth/Embedded Signup:

- `start`;
- `refresh`;
- `disconnect`.

### Ações WhatsApp por QR Code

Para o modo de sessão QR do WhatsApp:

- `start_qr`: cria uma sessão isolada para o workspace e gera um QR de pareamento;
- `refresh_qr`: invalida o QR anterior e gera outro QR curto/temporário;
- `disconnect`: encerra a sessão e para imediatamente novos envios.

O Flutter **não recebe o conteúdo da sessão do WhatsApp**. O backend deve retornar somente uma URL temporária HTTPS do próprio CormeX para uma página que mostra o QR Code. Essa URL deve expirar rapidamente e não pode permitir acesso a outro workspace.

### Iniciar WhatsApp QR

Request:

```json
{
  "workspaceId": "ws_01J...",
  "provider": "whatsapp",
  "action": "start_qr",
  "returnUrl": "https://tdk17.github.io/cormex_ai_agent/integrations",
  "clientRequestId": "integration_whatsapp_1788872400000"
}
```

Response esperado enquanto aguarda leitura do QR:

```json
{
  "ok": true,
  "data": {
    "status": "authorization_required",
    "authorizationUrl": "https://api.cormex.example/connect/whatsapp/qr/qr_01J...?ticket=one_time_token",
    "expiresAt": "2026-09-08T13:02:00.000Z",
    "integration": {
      "id": "integration_01J...",
      "provider": "whatsapp",
      "type": "messaging",
      "status": "connecting",
      "displayName": null,
      "maskedAccount": null,
      "capabilities": [],
      "requiresAction": true,
      "version": 1
    }
  },
  "meta": { "correlationId": "req_01J..." }
}
```

Depois que o cliente escanear o QR no próprio WhatsApp, `integrations.list` deve passar a retornar `status: connected` para aquele workspace.

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

1. encerrar/revogar a sessão no adaptador utilizado;
2. remover ou invalidar material de autenticação da sessão;
3. parar novos envios e jobs automáticos imediatamente;
4. preservar mensagens, leads, auditoria e métricas históricas;
5. invalidar estados, tickets de QR e webhooks pendentes daquela integração.

## 3. WhatsApp — arquitetura multi-tenant por QR

### Regra principal

Cada cliente do CormeX conecta **o próprio número**. A sessão pertence a um único `workspaceId`.

Exemplo:

```text
Workspace A -> sessão WA A -> número do Cliente A
Workspace B -> sessão WA B -> número do Cliente B
Workspace C -> sessão WA C -> número do Cliente C
```

Uma sessão nunca pode ser compartilhada entre workspaces.

### Fluxo

1. usuário autenticado abre Integrações;
2. front chama `integrations.connect` com `provider=whatsapp` e `action=start_qr`;
3. backend cria/recupera uma sessão exclusiva daquele workspace;
4. backend gera QR e devolve `authorizationUrl` temporária;
5. front abre essa URL;
6. cliente escaneia com **WhatsApp > Aparelhos conectados > Conectar um aparelho**;
7. adaptador confirma a sessão;
8. backend grava somente metadados públicos em `Integration` e mantém credenciais da sessão em armazenamento protegido;
9. `integrations.list` passa para `connected`;
10. motor de conversas passa a usar aquela sessão para receber/enviar mensagens daquele workspace.

### Requisitos obrigatórios do backend

- isolamento rígido por `workspaceId` e `integrationId`;
- uma chave lógica de sessão por workspace, por exemplo `wa:<workspaceId>`;
- não enviar cookies/credenciais da sessão ao Flutter;
- criptografar material de sessão em repouso;
- ticket da página de QR curto, aleatório, de uso limitado e expirável;
- regenerar QR quando expirar sem criar sessão duplicada;
- detectar `connected`, `disconnected`, `expired` e `authorization_error`;
- reconectar com a sessão persistida quando o worker reiniciar;
- impedir que dois workers controlem simultaneamente a mesma sessão;
- rate limit por workspace;
- auditoria de conectar, reconectar e desconectar;
- fila de mensagens por workspace para evitar mistura entre clientes;
- opt-out deve interromper IA, follow-ups e novos envios de marketing;
- cada mensagem externa deve manter `providerMessageId` para deduplicação e status.

### Adaptador

O backend deve implementar uma interface de canal para que o restante do CormeX não dependa diretamente da biblioteca escolhida:

```text
WhatsAppChannelAdapter
  startSession(workspaceId)
  getConnectionState(workspaceId)
  refreshQr(workspaceId)
  sendMessage(workspaceId, to, payload)
  disconnect(workspaceId)
  onInboundMessage(event)
  onDeliveryUpdate(event)
```

Assim, se futuramente o produto migrar para a API oficial da Meta, o CRM, a IA, as conversas e o pipeline continuam usando o mesmo contrato interno.

### Observação de produto

O modo QR/Web é uma integração não oficial e pode sofrer mudanças, desconexões ou restrições do WhatsApp. Por isso, ele deve ser tratado no CormeX como um **adaptador substituível**, e não como dependência estrutural do CRM. A opção oficial da Meta pode ser adicionada posteriormente sem alterar o fluxo comercial da IA.

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
| Desconectar | `admin` |

## 6. Persistência

Separar obrigatoriamente:

- `Integration`: estado e metadados públicos sanitizados;
- `IntegrationCredential` ou `ChannelSession`: material de autenticação criptografado e sem CLP/ACL de leitura do cliente;
- `OAuthState`: para fluxos OAuth;
- `QrConnectionTicket`: hash do ticket, workspace, integração, expiração e uso;
- `ProviderWebhookEvent`: hash/ID para deduplicação e auditoria.

## 7. Erros

`UNAUTHENTICATED`, `FORBIDDEN`, `WORKSPACE_NOT_FOUND`, `VALIDATION_ERROR`, `NOT_FOUND`, `CONFLICT`, `RATE_LIMITED`, `INTEGRATION_NOT_CONNECTED`, `AUTHORIZATION_ERROR`, `QR_EXPIRED`, `SESSION_DISCONNECTED`, `SESSION_CONFLICT`, `EXTERNAL_PROVIDER_ERROR`, `INTERNAL_ERROR`.

## 8. Critérios de aceite

- [ ] cada workspace possui sua própria sessão WhatsApp;
- [ ] um workspace nunca consegue consultar QR/sessão de outro;
- [ ] `start_qr`, `refresh_qr` e `disconnect` são idempotentes;
- [ ] QR/ticket expiram rapidamente;
- [ ] sessão continua válida após reinício do worker quando o WhatsApp permitir;
- [ ] nenhum cookie, token ou segredo de sessão aparece no bundle, response ou log;
- [ ] revogação para jobs automáticos imediatamente;
- [ ] eventos recebidos são deduplicados;
- [ ] mensagens e filas sempre carregam `workspaceId`/`integrationId` internamente;
- [ ] auditoria registra ator, ação, integração e `correlationId`;
- [ ] existe caminho de migração para um adaptador oficial sem alterar CRM/IA/pipeline.
