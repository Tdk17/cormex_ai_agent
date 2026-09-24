# API da tela de Login

Contrato usado por `LoginPage`, `LoginController`, `AuthController` e `RemoteAuthRepository`.

## Objetivo do fluxo

1. Autenticar o usuário no Parse Server.
2. Carregar usuário, empresas e memberships pela sessão.
3. Se existir empresa vinculada, selecionar a última empresa válida e abrir `/acquisition`.
4. Se a conta não possuir empresa, abrir `/onboarding`.
5. Em logins futuros, nunca solicitar novamente a criação da empresa já vinculada.
6. Nunca liberar as rotas internas usando apenas uma sessão salva no dispositivo.

## 1. Login protegido

```http
POST /functions/v1-auth-login
X-Parse-Application-Id: <application-id>
X-Parse-REST-API-Key: <rest-api-key>
Content-Type: application/json
```

```json
{
  "email": "pedro@empresa.com",
  "password": "<senha>"
}
```

Resposta:

```json
{
  "result": {
    "ok": true,
    "data": {
      "id": "user_01J...",
      "objectId": "user_01J...",
      "name": "Pedro Henrique",
      "email": "pedro@empresa.com",
      "username": "pedro@empresa.com",
      "sessionToken": "r:session-token"
    },
    "meta": {
      "correlationId": "req_01J..."
    }
  }
}
```

Proteções obrigatórias:

- 5 falhas para o mesmo e-mail em 15 minutos bloqueiam a conta por 15 minutos;
- 20 falhas pelo mesmo IP em 15 minutos bloqueiam a origem por 30 minutos;
- e-mail e IP são persistidos apenas como hash na classe `AuthLoginAttempt`;
- usuário inexistente e senha incorreta sempre devolvem a mesma mensagem;
- um login correto limpa o contador da conta;
- o front não informa se o bloqueio ocorreu por conta ou IP;
- o endpoint nativo `/login` não deve ser usado pelo Flutter;
- o `accountLockout` nativo do Parse Server também deve ser ativado no Back4App para proteger chamadas diretas a `/login`.

O token é salvo pelo Flutter no armazenamento seguro e enviado nas chamadas seguintes em `X-Parse-Session-Token`.

## 2. `v1-auth-me`

Executada automaticamente após o login e ao restaurar uma sessão salva.

Request:

```json
{}
```

Response:

```json
{
  "ok": true,
  "data": {
    "user": {
      "id": "user_01J...",
      "name": "Pedro Henrique",
      "email": "pedro@empresa.com"
    },
    "workspaces": [
      {
        "id": "ws_01J...",
        "name": "CormeX Tecnologia",
        "timezone": "America/Sao_Paulo",
        "companySegment": "Software e tecnologia"
      }
    ],
    "memberships": [
      {
        "id": "membership_01J...",
        "userId": "user_01J...",
        "workspaceId": "ws_01J...",
        "role": "owner"
      }
    ]
  },
  "meta": {
    "correlationId": "req_01J..."
  }
}
```

Regras obrigatórias do backend:

- exigir `request.user` válido;
- retornar somente workspaces com membership ativa do usuário;
- nunca confiar em workspace armazenado apenas no dispositivo;
- não retornar token, senha, Master Key ou credenciais de integrações;
- devolver arrays vazios quando a conta ainda não possui empresa;
- manter `workspaceId` e `userId` como strings nos DTOs.

## 3. Redirecionamento do front

```text
sessão inválida                         → /login
sessão válida + workspaces vazio        → /onboarding
sessão válida + workspace vinculado     → /acquisition
```

Esse guard está centralizado em `lib/Src/Core/router/app_router.dart`.

Antes de considerar o usuário autenticado, o Flutter exige duas confirmações reais:

1. `v1-auth-login` precisa devolver `objectId` e `sessionToken` não vazios;
2. `v1-auth-me` precisa devolver o mesmo usuário da sessão e memberships válidas.

Se `v1-auth-login`, `v1-auth-me`, a rede ou a validação falhar, a sessão segura é apagada e o usuário permanece no Login. Sessões antigas da fase de desenvolvimento usam uma chave anterior e são descartadas automaticamente.

## 4. Logout

```http
POST /logout
X-Parse-Session-Token: <session-token>
```

Mesmo que o servidor falhe, o Flutter limpa a sessão local para não manter acesso visual indevido.

## 5. Recuperação de senha

```http
POST /requestPasswordReset
Content-Type: application/json
```

```json
{
  "email": "pedro@empresa.com"
}
```

Por segurança, a resposta não deve revelar se o e-mail existe.

## 6. Erros esperados

| Código | Comportamento no front |
| --- | --- |
| `INVALID_CREDENTIALS` | Exibe “E-mail ou senha inválidos”. |
| `UNAUTHENTICATED` | Limpa a sessão e volta ao login. |
| `RATE_LIMITED` | Solicita que o usuário aguarde. |
| `NETWORK_ERROR` | Exibe falha de conexão. |
| `INTERNAL_ERROR` | Exibe mensagem genérica e `correlationId`. |

## 7. Arquivos Flutter

- `lib/Src/Features/auth/presentation/pages/login_page.dart`
- `lib/Src/Features/auth/presentation/controllers/login_controller.dart`
- `lib/Src/Features/auth/presentation/controllers/auth_controller.dart`
- `lib/Src/Features/auth/data/remote_auth_repository.dart`
- `lib/Src/Core/auth/session_storage.dart`
- `lib/Src/Core/router/app_router.dart`
