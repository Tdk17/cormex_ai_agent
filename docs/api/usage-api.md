# API — Plano e uso

Tela planejada: `/usage`  
Função nominal preservada: `usage.current`

## `usage.current`

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
    "plan": {
      "id": "growth_monthly",
      "name": "Growth",
      "price": 299.9,
      "currency": "BRL",
      "billingCycle": "monthly",
      "status": "active",
      "renewsAt": "2026-10-01T00:00:00.000Z",
      "features": [
        "Atendimento com IA",
        "Google Ads",
        "Até 5 membros"
      ]
    },
    "usage": {
      "periodStart": "2026-09-01T00:00:00.000Z",
      "periodEnd": "2026-10-01T00:00:00.000Z",
      "aiMessagesUsed": 420,
      "aiMessagesLimit": 2000,
      "leadsUsed": 118,
      "leadsLimit": 1000,
      "membersUsed": 3,
      "membersLimit": 5,
      "storageBytesUsed": 53477376,
      "storageBytesLimit": 1073741824,
      "campaignsActive": 2,
      "campaignsActiveLimit": 10
    },
    "warnings": [
      {
        "metric": "members",
        "level": "warning",
        "percentage": 60,
        "message": "Você está usando 3 de 5 membros."
      }
    ]
  },
  "meta": { "correlationId": "req_01J..." }
}
```

Os seis campos já usados pelo model compartilhado são:

- `aiMessagesUsed`, `aiMessagesLimit`;
- `leadsUsed`, `leadsLimit`;
- `membersUsed`, `membersLimit`.

Campos adicionais devem ser retrocompatíveis.

## Regras de contabilização

- contabilizar no workspace que consumiu o recurso, nunca no usuário isolado;
- usar operações atômicas e idempotentes para não contar retry duas vezes;
- mensagem de IA conta apenas quando o provedor confirmou uma resposta utilizável;
- lead conta uma única vez, mesmo se o webhook for reenviado;
- membro conta apenas membership ativa;
- separar gasto de mídia do Google/Meta da assinatura do CormeX;
- não usar números enviados pelo Flutter para atualizar consumo;
- manter trilha por período para auditoria e reconciliação.

## Aplicação de limite

As funções que criam o recurso devem verificar o limite antes da operação. Ao atingir limite rígido:

```json
{
  "ok": false,
  "error": {
    "code": "PLAN_LIMIT_REACHED",
    "message": "O limite de mensagens de IA do plano foi atingido.",
    "correlationId": "req_01J...",
    "details": {
      "metric": "aiMessages",
      "used": 2000,
      "limit": 2000,
      "periodEnd": "2026-10-01T00:00:00.000Z"
    }
  }
}
```

Não bloquear leitura de dados históricos por limite de criação. Em limite de IA, preservar atendimento humano.

## Autorização

- `owner/admin`: plano, valores, uso e limites completos;
- `seller`: somente indicadores necessários para explicar bloqueios operacionais, sem dados financeiros sensíveis.

## Erros

`UNAUTHENTICATED`, `FORBIDDEN`, `WORKSPACE_NOT_FOUND`, `NOT_FOUND`, `RATE_LIMITED`, `INTERNAL_ERROR`.

## Critérios de aceite

- [ ] contadores são atômicos e reconciliáveis;
- [ ] retries não duplicam consumo;
- [ ] período e renovação são devolvidos em UTC;
- [ ] downgrade não apaga dados;
- [ ] gasto de anúncios nunca aparece como preço do SaaS;
- [ ] limites são aplicados também em workers e webhooks.
