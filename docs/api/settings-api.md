# API — Configurações da empresa

Tela planejada: `/settings`

Estas funções ainda não estão registradas em `Endpoints`. O contrato abaixo reserva nomes versionados; o Flutter só deve chamá-los depois que as constantes forem adicionadas numa mudança coordenada.

## 1. `v1-workspace-settings-get`

### Request

```json
{
  "workspaceId": "ws_01J..."
}
```

### Response

```json
{
  "ok": true,
  "data": {
    "settings": {
      "workspaceId": "ws_01J...",
      "name": "Genesys System",
      "companySegment": "tecnologia",
      "timezone": "America/Sao_Paulo",
      "locale": "pt_BR",
      "currency": "BRL",
      "businessEmail": "contato@empresa.com",
      "businessPhone": "+5511999999999",
      "defaultPipelineStageId": "stage_new",
      "dataRetentionDays": 365,
      "version": 4
    }
  },
  "meta": { "correlationId": "req_01J..." }
}
```

## 2. `v1-workspace-settings-update`

### Request

```json
{
  "workspaceId": "ws_01J...",
  "changes": {
    "name": "Genesys System",
    "companySegment": "tecnologia",
    "timezone": "America/Sao_Paulo",
    "locale": "pt_BR",
    "currency": "BRL",
    "businessEmail": "contato@empresa.com",
    "businessPhone": "+5511999999999",
    "defaultPipelineStageId": "stage_new",
    "dataRetentionDays": 365
  },
  "expectedVersion": 4,
  "clientRequestId": "workspace_settings_1725192000000"
}
```

### Response

`{ "ok": true, "data": { "settings": {} } }` com DTO completo e `version=5`.

### Regras

- aceitar somente allowlist de campos;
- validar fuso IANA e locale suportado;
- moeda deve ser ISO 4217;
- telefone preferencialmente E.164;
- `defaultPipelineStageId` precisa pertencer ao workspace;
- mudança de fuso afeta apenas agendamentos futuros; jobs existentes devem ser recalculados de forma auditável;
- apenas `owner/admin` podem atualizar;
- responder `CONFLICT` quando `expectedVersion` divergir.

## 3. Exclusão da empresa

A exclusão é deliberadamente dividida em duas operações para reduzir erros irreversíveis.

### `v1-workspace-delete-request`

```json
{
  "workspaceId": "ws_01J...",
  "confirmationName": "Genesys System",
  "reason": "Encerramento da operação",
  "clientRequestId": "workspace_delete_1725192000000"
}
```

Somente `owner`. O backend deve exigir autenticação recente, impedir operação quando houver transferência/pendência obrigatória e devolver:

```json
{
  "ok": true,
  "data": {
    "deletionRequestId": "delete_01J...",
    "status": "confirmation_required",
    "expiresAt": "2026-09-03T15:15:00.000Z"
  },
  "meta": { "correlationId": "req_01J..." }
}
```

Enviar o código/token de confirmação por canal verificado; nunca retornar o token completo no response.

### `v1-workspace-delete-confirm`

```json
{
  "workspaceId": "ws_01J...",
  "deletionRequestId": "delete_01J...",
  "confirmationCode": "123456",
  "clientRequestId": "workspace_delete_confirm_1725192000000"
}
```

Response:

```json
{
  "ok": true,
  "data": {
    "workspaceId": "ws_01J...",
    "status": "scheduled",
    "scheduledFor": "2026-09-10T15:00:00.000Z",
    "recoverableUntil": "2026-09-10T15:00:00.000Z"
  },
  "meta": { "correlationId": "req_01J..." }
}
```

Preferir exclusão agendada/recuperável antes da purga final. Ao confirmar:

1. bloquear novas campanhas, mensagens automáticas e convites;
2. desconectar/revogar integrações;
3. cancelar jobs;
4. preservar trilha de auditoria exigida por lei/política;
5. executar anonimização/purga conforme retenção aplicável;
6. remover o workspace da resposta de `v1-auth-me` quando ficar inativo.

## Segurança e auditoria

- não permitir alteração de `ownerId`, assinatura ou credenciais nestas funções;
- não aceitar segredos de integração em `changes`;
- auditar valor anterior e novo apenas para campos não sensíveis;
- mascarar e-mail/telefone em logs;
- exigir confirmação explícita para ações destrutivas;
- respeitar requisitos de privacidade e retenção definidos para a operação.

## Erros

`UNAUTHENTICATED`, `FORBIDDEN`, `WORKSPACE_NOT_FOUND`, `VALIDATION_ERROR`, `NOT_FOUND`, `CONFLICT`, `RATE_LIMITED`, `INTERNAL_ERROR`.
