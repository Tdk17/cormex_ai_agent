# CRM — Clientes e Empresas/Contas

Contrato de backend necessário para as telas `/crm/customers` e `/crm/accounts`.

## Regra de domínio

- **Lead**: potencial comprador ainda em qualificação.
- **Customer / Cliente**: pessoa/contato que já é cliente e pode existir sem ter vindo de um Lead.
- **Account / Empresa**: organização/conta B2B atendida pelo workspace.
- Um Customer pode futuramente possuir `accountId` para representar um contato de uma empresa, sem transformar Customer e Account na mesma entidade.
- Toda consulta e mutação é obrigatoriamente isolada por `workspaceId` validado pela Membership no servidor.

## Permissões

- `owner` e `admin`: listar, criar e editar todos os registros do workspace.
- `seller`: listar e criar; edição pode ser limitada aos registros próprios conforme política comercial.
- Nunca confiar no `workspaceId` recebido sem validar Membership ativa.

## `v1-customers-list`

Request:

```json
{ "workspaceId": "ws_123", "limit": 100, "cursor": null }
```

Response:

```json
{
  "ok": true,
  "data": {
    "items": [
      {
        "id": "cus_123",
        "workspaceId": "ws_123",
        "name": "Maria Silva",
        "email": "maria@empresa.com.br",
        "phone": "+5547999999999",
        "document": "00000000000",
        "accountId": "acc_123",
        "status": "active",
        "ownerId": "user_123",
        "source": "manual",
        "tags": []
      }
    ]
  },
  "meta": { "nextCursor": null, "correlationId": "req_..." }
}
```

## `v1-customers-create`

Request:

```json
{
  "workspaceId": "ws_123",
  "customer": {
    "name": "Maria Silva",
    "email": "maria@empresa.com.br",
    "phone": "+5547999999999",
    "document": "00000000000",
    "accountId": "acc_123"
  },
  "clientRequestId": "crm_customer_..."
}
```

Regras: `name` obrigatório; normalizar telefone/documento; e-mail opcional e validado; `accountId` deve pertencer ao mesmo workspace; criação manual é permitida e não depende de conversão de Lead.

Response: `data.customer` com o registro persistido.

## `v1-customers-get`

Request: `{ "workspaceId": "ws_123", "customerId": "cus_123" }`.

Response: `data.customer`.

## `v1-customers-update`

Request:

```json
{
  "workspaceId": "ws_123",
  "customerId": "cus_123",
  "customer": { "name": "Maria Silva", "phone": "+5547999999999" },
  "expectedVersion": 2,
  "clientRequestId": "crm_customer_update_..."
}
```

Response: `data.customer` atualizado e `version` incrementada.

## `v1-accounts-list`

Request:

```json
{ "workspaceId": "ws_123", "limit": 100, "cursor": null }
```

Response:

```json
{
  "ok": true,
  "data": {
    "items": [
      {
        "id": "acc_123",
        "workspaceId": "ws_123",
        "name": "Empresa XPTO",
        "legalName": "XPTO Comércio Ltda",
        "document": "00000000000100",
        "website": "https://empresa.com.br",
        "phone": "+554733333333",
        "address": "...",
        "ownerId": "user_123",
        "tags": []
      }
    ]
  },
  "meta": { "nextCursor": null, "correlationId": "req_..." }
}
```

## `v1-accounts-create`

Request:

```json
{
  "workspaceId": "ws_123",
  "account": {
    "name": "Empresa XPTO",
    "legalName": "XPTO Comércio Ltda",
    "document": "00000000000100",
    "website": "https://empresa.com.br",
    "phone": "+554733333333"
  },
  "clientRequestId": "crm_account_..."
}
```

`name` é obrigatório. O CNPJ/documento deve ser normalizado. Duplicidade deve ser verificada dentro do mesmo workspace, não globalmente.

Response: `data.account`.

## `v1-accounts-get` e `v1-accounts-update`

Seguem o mesmo padrão de Customers usando `accountId`, `expectedVersion` e `clientRequestId`.

## Classes Parse sugeridas

### Customer
`workspaceId`, `name`, `email`, `phone`, `document`, `accountId`, `status`, `ownerId`, `source`, `tags`, `version`, `createdAt`, `updatedAt`.

### Account
`workspaceId`, `name`, `legalName`, `document`, `website`, `phone`, `address`, `ownerId`, `tags`, `version`, `createdAt`, `updatedAt`.

## Índices mínimos

- Customer: `(workspaceId, name)`, `(workspaceId, email)`, `(workspaceId, document)`, `(workspaceId, accountId)`.
- Account: `(workspaceId, name)`, `(workspaceId, document)`.

## Google Ads — correção necessária no backend de produção

O front usa `v1-google-ads-oauth-start` e envia a URL atual da tela como `returnUrl`. Depois da publicação no domínio `https://cormexcrm.com.br`, o backend precisa incluir na allowlist pelo menos:

- `https://cormexcrm.com.br`
- `https://cormexcrm.com.br/integrations`
- para desenvolvimento local, apenas as origens explicitamente autorizadas pelo backend

Se a função ainda permitir apenas a origem antiga do GitHub Pages, o novo domínio será rejeitado antes de abrir o consentimento do Google, podendo aparecer ao usuário como erro de autorização/permissão.

Também confirme no Google Cloud que a conta usada para teste está cadastrada em **Test users** enquanto o OAuth estiver em modo Testing. Isso é independente do papel `owner/admin` do CormeX.
