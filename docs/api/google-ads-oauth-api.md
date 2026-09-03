# Integração Google Ads — OAuth 2.0 e publicação

Este documento define o contrato necessário no backend Back4App para a tela **Integrações** do CormeX. Nenhuma credencial privada do Google Ads deve ser compilada no Flutter ou versionada no GitHub.

## Credenciais privadas no backend

Configure no ambiente privado do Back4App:

- `GOOGLE_ADS_CLIENT_ID`
- `GOOGLE_ADS_CLIENT_SECRET`
- `GOOGLE_ADS_DEVELOPER_TOKEN`
- `GOOGLE_ADS_OAUTH_REDIRECT_URI`
- `GOOGLE_ADS_LOGIN_CUSTOMER_ID` apenas quando a arquitetura usar uma conta manager e esse header for necessário.

O OAuth deve solicitar o escopo:

`https://www.googleapis.com/auth/adwords`

Para permitir que campanhas continuem sendo administradas quando o usuário não estiver com o CormeX aberto, o fluxo Web deve solicitar `access_type=offline`. O refresh token deve ficar exclusivamente no backend.

## 1. `v1-google-ads-connection-status`

Cloud Function autenticada usada pelo Flutter para saber se o workspace já possui autorização válida.

### Request

```json
{
  "workspaceId": "ws_123"
}
```

### Response desconectada

```json
{
  "ok": true,
  "data": {
    "connected": false,
    "status": "disconnected",
    "account": null
  }
}
```

### Response conectada

```json
{
  "ok": true,
  "data": {
    "connected": true,
    "status": "connected",
    "account": {
      "name": "Conta principal",
      "customerId": "1234567890"
    }
  }
}
```

Nunca retornar access token, refresh token, client secret ou developer token.

## 2. `v1-google-ads-oauth-start`

Cloud Function autenticada que cria uma tentativa OAuth vinculada ao usuário e workspace e devolve somente a URL oficial de autorização do Google.

### Request

```json
{
  "workspaceId": "ws_123",
  "returnUrl": "https://tdk17.github.io/cormex_ai_agent/integrations"
}
```

### Backend

1. validar `request.user`;
2. validar membership no `workspaceId`;
3. validar `returnUrl` contra uma allowlist de origens CormeX;
4. gerar `state` criptograficamente aleatório e de uso único;
5. persistir hash do state, `workspaceId`, `userId`, `returnUrl` e expiração curta;
6. construir URL `https://accounts.google.com/o/oauth2/v2/auth` com:
   - `client_id` do servidor;
   - `redirect_uri` exatamente igual ao cadastrado no Google Cloud;
   - `response_type=code`;
   - `scope=https://www.googleapis.com/auth/adwords`;
   - `access_type=offline`;
   - `include_granted_scopes=true`;
   - `prompt=consent` quando for necessário obter um refresh token novo;
   - `state` de uso único.

### Response

```json
{
  "ok": true,
  "data": {
    "authorizationUrl": "https://accounts.google.com/o/oauth2/v2/auth?..."
  }
}
```

## 3. Callback HTTP do Google

O `GOOGLE_ADS_OAUTH_REDIRECT_URI` deve apontar para uma rota HTTP GET controlada pelo backend, por exemplo:

`https://SEU_DOMINIO_BACK4APP.com/oauth/google-ads/callback`

Essa rota não deve confiar em `workspaceId` vindo diretamente da query. Ela deve recuperar workspace e usuário a partir do `state` persistido.

### Fluxo

1. receber `code` e `state`;
2. validar state, expiração e uso único;
3. trocar `code` por tokens em `https://oauth2.googleapis.com/token` usando `GOOGLE_ADS_CLIENT_ID`, `GOOGLE_ADS_CLIENT_SECRET` e o mesmo redirect URI;
4. armazenar o refresh token criptografado/isolado no servidor;
5. usar o access token e o `GOOGLE_ADS_DEVELOPER_TOKEN` para consultar `customers:listAccessibleCustomers`;
6. persistir apenas os IDs de contas que o usuário realmente pode acessar;
7. marcar a integração como `connected`;
8. invalidar o state;
9. redirecionar para o `returnUrl` previamente validado.

## 4. Persistência sugerida

Classe protegida `GoogleAdsConnection`:

- `workspaceId`
- `userId`
- `status`
- `refreshTokenEncrypted`
- `googleAccountSubject` opcional
- `selectedCustomerId`
- `accessibleCustomerIds`
- `accountName`
- `createdAt`
- `updatedAt`
- `lastValidatedAt`

CLP/ACL deve impedir leitura direta pelo cliente Flutter. Toda leitura pública ao app passa por Cloud Functions sanitizadas.

Classe protegida `GoogleAdsOAuthState`:

- `stateHash`
- `workspaceId`
- `userId`
- `returnUrl`
- `expiresAt`
- `usedAt`

## 5. Funções complementares de conta

As três funções abaixo completam a seleção e a revogação da conta. Elas ainda não estão registradas no `Endpoints` Flutter; adicione as constantes somente quando a interface passar a chamá-las.

### `v1-google-ads-accounts`

Lista contas acessíveis com a autorização já concluída.

Request:

```json
{
  "workspaceId": "ws_123"
}
```

Response:

```json
{
  "ok": true,
  "data": {
    "accounts": [
      {
        "customerId": "1234567890",
        "descriptiveName": "Conta principal",
        "currency": "BRL",
        "timezone": "America/Sao_Paulo",
        "manager": false,
        "selected": true,
        "accessible": true
      }
    ]
  },
  "meta": { "correlationId": "req_01J..." }
}
```

O backend deve consultar contas acessíveis e, quando houver manager account, percorrer `customer_client` de forma controlada. Não confiar apenas em IDs persistidos anteriormente; revalidar acesso.

### `v1-google-ads-select-account`

Request:

```json
{
  "workspaceId": "ws_123",
  "customerId": "1234567890",
  "loginCustomerId": "0987654321",
  "clientRequestId": "google_ads_select_1725192000000"
}
```

`loginCustomerId` é opcional e só deve ser usado quando a hierarquia exigir. Ambos os IDs devem ser normalizados para dígitos.

Response:

```json
{
  "ok": true,
  "data": {
    "connected": true,
    "status": "connected",
    "account": {
      "name": "Conta principal",
      "customerId": "1234567890",
      "currency": "BRL"
    }
  },
  "meta": { "correlationId": "req_01J..." }
}
```

Antes de salvar, confirmar que a conta está acessível pelo refresh token atual e que a credencial tem permissão suficiente para a operação pretendida.

### `v1-google-ads-disconnect`

Request:

```json
{
  "workspaceId": "ws_123",
  "clientRequestId": "google_ads_disconnect_1725192000000"
}
```

Response:

```json
{
  "ok": true,
  "data": {
    "connected": false,
    "status": "disconnected",
    "account": null
  },
  "meta": { "correlationId": "req_01J..." }
}
```

Revogar o token no Google quando possível, inutilizar a credencial local, cancelar sincronizações futuras e preservar histórico de campanhas/métricas.

## 6. Publicação de campanha

`v1-acquisition-campaign-publish` deve, para campanhas com canal `google`:

1. carregar `GoogleAdsConnection` do workspace;
2. renovar access token pelo refresh token;
3. incluir `Authorization: Bearer <access_token>` e `developer-token` nas chamadas Google Ads;
4. incluir `login-customer-id` somente quando aplicável;
5. validar a conta/customer selecionada;
6. criar budget, campaign, ad group, assets e anúncio de acordo com o objetivo/formato suportado;
7. salvar os IDs externos em `providerCampaignIds.google`;
8. nunca retornar credenciais ao Flutter.

## 7. Segurança

- não guardar Client Secret, developer token ou refresh token no Flutter;
- não usar `--dart-define` para segredos OAuth do Google Ads;
- não versionar segredos no GitHub;
- `state` deve ser randômico, curto e de uso único;
- `returnUrl` deve usar allowlist para impedir open redirect;
- registrar auditoria de conexão, publicação, pausa e alteração de orçamento;
- revogação/erro de autorização deve alterar a integração para `authorization_error`;
- logs devem mascarar tokens e códigos OAuth.

## 8. Erros esperados

| Código | Uso |
| --- | --- |
| `GOOGLE_ADS_NOT_CONFIGURED` | variáveis privadas ausentes |
| `GOOGLE_OAUTH_STATE_INVALID` | state desconhecido ou adulterado |
| `GOOGLE_OAUTH_STATE_EXPIRED` | state expirado |
| `GOOGLE_OAUTH_STATE_USED` | state já consumido |
| `GOOGLE_OAUTH_CODE_MISSING` | callback sem authorization code |
| `GOOGLE_OAUTH_CODE_EXCHANGE_FAILED` | falha segura na troca do code |
| `GOOGLE_REFRESH_TOKEN_MISSING` | Google não devolveu refresh token utilizável |
| `GOOGLE_ADS_ACCOUNT_NOT_FOUND` | conta não encontrada |
| `GOOGLE_ADS_ACCOUNT_NOT_ACCESSIBLE` | credencial sem acesso à conta |
| `GOOGLE_ADS_AUTHORIZATION_ERROR` | autorização expirada/revogada |
| `GOOGLE_ADS_PERMISSION_ERROR` | acesso insuficiente |
| `GOOGLE_ADS_DEVELOPER_TOKEN_ERROR` | developer token inválido/não aprovado |
| `GOOGLE_ADS_API_ERROR` | erro normalizado da API externa |
| `GOOGLE_ADS_PUBLICATION_ERROR` | mutação da campanha não concluída |

## 9. Google Cloud Console

Antes de o botão **Entrar com Google** funcionar:

1. habilitar Google Ads API no projeto Google Cloud;
2. configurar a tela de consentimento OAuth;
3. criar OAuth Client do tipo **Web application**;
4. cadastrar exatamente o `GOOGLE_ADS_OAUTH_REDIRECT_URI` como Authorized redirect URI;
5. se o app estiver em modo Testing, adicionar as contas Google usadas nos testes como test users;
6. obter/aprovar um Google Ads developer token na API Center da conta manager.

O token do Google Ads e as credenciais OAuth são responsabilidades diferentes: o OAuth autoriza o usuário/conta; o developer token autoriza o aplicativo a utilizar a Google Ads API.

## 10. Referências oficiais

- [Google Ads API — OAuth 2.0](https://developers.google.com/google-ads/api/docs/oauth/overview)
- [Google Ads API — hierarquia de contas](https://developers.google.com/google-ads/api/docs/account-management/get-account-hierarchy)
- [Google Ads Lead Form Webhook](https://developers.google.com/google-ads/webhook/docs/overview)
