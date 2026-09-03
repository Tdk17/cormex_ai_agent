# API — Equipe e papéis

Tela: `/team`

## `v1-team-list`

Request: `{ "workspaceId": "ws_01J..." }`

Response:

```json
{
  "ok": true,
  "data": {
    "members": [
      {
        "membershipId": "membership_01J...",
        "user": {
          "id": "user_01J...",
          "name": "Ana Souza",
          "email": "ana@empresa.com"
        },
        "role": "admin",
        "status": "active",
        "lastActiveAt": "2026-09-03T14:00:00.000Z",
        "version": 2
      }
    ],
    "invitations": []
  },
  "meta": { "correlationId": "req_01J..." }
}
```

## `v1-team-invite`

```json
{
  "workspaceId": "ws_01J...",
  "email": "vendedor@empresa.com",
  "role": "seller",
  "clientRequestId": "team_invite_1725192000000"
}
```

Aceitar `admin` ou `seller`. Apenas `owner/admin` podem convidar. O backend normaliza e-mail, impede convite duplicado ativo, cria token de uso único com expiração e envia o convite fora da requisição quando possível.

Response: `{ "ok": true, "data": { "invitation": {} } }`.

## `v1-team-update-role`

```json
{
  "workspaceId": "ws_01J...",
  "membershipId": "membership_01J...",
  "role": "admin",
  "expectedVersion": 2
}
```

Response: `{ "ok": true, "data": { "member": {} } }` com DTO completo e versão incrementada.

Regras:

- `owner`: controle total e nunca pode ser removido/rebaixado por esta função;
- `admin`: configura workspace, integrações, agente, conhecimento, follow-ups e equipe, sem transferir propriedade;
- `seller`: opera leads, Pipeline e conversas conforme políticas;
- impedir que um usuário altere dados de outro workspace;
- registrar auditoria de convite e troca de papel;
- responder `CONFLICT` quando `expectedVersion` estiver desatualizada.
