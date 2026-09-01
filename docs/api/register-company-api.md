# API das telas de Cadastro e Criação da Empresa

Contrato das telas `/register` e `/onboarding`. O fluxo cria a conta e, em seguida, cria a primeira empresa exatamente uma vez.

## Fluxo completo

```text
Cadastro da conta
  → sessão Parse criada
  → onboarding da empresa
  → v1-workspaces-create atômica e idempotente
  → Workspace + Membership owner + configuração inicial do agente
  → sessão local atualizada
  → Central de Aquisição (`/acquisition`)
```

Depois disso, `v1-auth-me` encontra a membership e os próximos logins seguem diretamente para a Central de Aquisição. O Dashboard continua disponível como visão analítica.

## 1. Criar conta Parse

```http
POST /users
Content-Type: application/json
X-Parse-Application-Id: <application-id>
X-Parse-REST-API-Key: <rest-api-key>
```

```json
{
  "name": "Pedro Henrique",
  "username": "pedro@empresa.com",
  "email": "pedro@empresa.com",
  "password": "<senha-com-8-ou-mais-caracteres>"
}
```

Resposta padrão do Parse:

```json
{
  "objectId": "user_01J...",
  "createdAt": "2026-08-24T18:00:00.000Z",
  "sessionToken": "r:session-token"
}
```

Validações do front: nome completo, e-mail válido, senha mínima de oito caracteres, confirmação igual e aceite dos termos. O backend deve repetir as validações relevantes.

## 2. `v1-workspaces-create`

Essa função deve criar a empresa, a membership do proprietário e a configuração inicial do agente na mesma operação lógica.

Request:

```json
{
  "name": "CormeX Tecnologia",
  "timezone": "America/Sao_Paulo",
  "companySegment": "Software e tecnologia",
  "idempotencyKey": "onboarding:user_01J...",
  "initialAgent": {
    "name": "Clara",
    "objective": "Qualificar leads e agendar demonstrações comerciais.",
    "mode": "assist"
  }
}
```

Response:

```json
{
  "ok": true,
  "data": {
    "workspace": {
      "id": "ws_01J...",
      "name": "CormeX Tecnologia",
      "timezone": "America/Sao_Paulo",
      "companySegment": "Software e tecnologia"
    },
    "membership": {
      "id": "membership_01J...",
      "userId": "user_01J...",
      "workspaceId": "ws_01J...",
      "role": "owner"
    },
    "agent": {
      "id": "agent_01J...",
      "workspaceId": "ws_01J...",
      "name": "Clara",
      "objective": "Qualificar leads e agendar demonstrações comerciais.",
      "mode": "assist"
    }
  },
  "meta": {
    "correlationId": "req_01J..."
  }
}
```

## 3. Garantia “criar somente uma vez”

O backend deve aplicar todas estas regras:

1. Exigir usuário autenticado.
2. Usar `idempotencyKey` como chave única lógica por usuário.
3. Antes de criar, procurar uma operação concluída com a mesma chave.
4. Se já existir, devolver o mesmo Workspace, Membership e Agent sem criar duplicados.
5. Se o usuário já possuir uma membership `owner` criada pelo onboarding, devolver a empresa existente.
6. Criar Workspace, Membership e Agent em operação protegida; uma falha não pode deixar uma empresa órfã.
7. Definir `role=owner` exclusivamente no servidor.
8. Não aceitar `userId` ou `workspaceId` escolhidos pelo cliente.

No Parse/Back4App, recomenda-se armazenar a chave em `OnboardingOperation` com ACL restrita e consultar/criar essa operação dentro da Cloud Function. A proteção contra duas chamadas simultâneas precisa estar no servidor.

## 4. Classes mínimas no Back4App

### `Workspace`

`name`, `timezone`, `companySegment`, `createdBy`, `onboardingKey`, `createdAt`, `updatedAt`.

### `Membership`

`user`, `workspace`, `role`, `status`, `createdAt`, `updatedAt`.

### `AgentConfig`

`workspace`, `name`, `objective`, `mode`, `createdAt`, `updatedAt`.

### `OnboardingOperation`

`key`, `user`, `workspace`, `membership`, `agent`, `status`.

## 5. Erros esperados

| Código | Quando usar |
| --- | --- |
| `UNAUTHENTICATED` | Sessão ausente ou expirada. |
| `VALIDATION_ERROR` | Dados da empresa ou do agente inválidos. |
| `CONFLICT` | E-mail já usado ou conflito não recuperável. |
| `PLAN_LIMIT_REACHED` | Regra de plano impedir nova empresa. |
| `RATE_LIMITED` | Excesso de tentativas. |
| `INTERNAL_ERROR` | Falha inesperada com `correlationId`. |

## 6. Arquivos Flutter

- `lib/Src/Features/auth/presentation/pages/register_page.dart`
- `lib/Src/Features/auth/data/remote_auth_repository.dart`
- `lib/Src/Features/onboarding/presentation/pages/onboarding_page.dart`
- `lib/Src/Features/onboarding/presentation/controllers/onboarding_controller.dart`
- `lib/Src/Core/router/app_router.dart`
