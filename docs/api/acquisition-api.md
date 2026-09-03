# API da Central de Aquisição

Contrato das rotas `/acquisition`, `/acquisition/new`, `/acquisition/:campaignId` e `/acquisition/:campaignId/edit`. A feature usa somente repositories remotos e mantém todos os nomes de Cloud Functions em `Endpoints`.

## Princípios obrigatórios

- Toda função exige sessão Parse e membership ativa no `workspaceId` solicitado.
- O backend é a fonte de verdade para autorização, orçamento, publicação, provedores, auditoria e isolamento do tenant.
- Tokens de Google/Meta, segredos OAuth, formas de pagamento e payloads internos nunca retornam ao Flutter.
- O gasto de mídia pertence ao anunciante e é cobrado pelo provedor, separado da assinatura CormeX.
- IA pode sugerir conteúdo e segmentação, mas nunca publica nem aumenta orçamento sem autorização explícita.
- Operações repetíveis usam `clientRequestId`; mutações sobre campanha existente usam `expectedVersion`.
- O envelope REST do Parse é `result`; dentro dele permanece o contrato `{ ok, data, meta }`.

## 1. `v1-acquisition-overview`

Alimenta a tela principal, incluindo métricas, contas autorizadas e campanhas paginadas.

### Request

```json
{
  "workspaceId": "workspace_01J...",
  "period": "30d",
  "channel": "meta",
  "status": "active",
  "cursor": null,
  "limit": 20
}
```

`channel`, `status` e `cursor` são opcionais. `period` aceita `7d`, `30d` ou `90d`. O cursor é opaco.

### Response

```json
{
  "ok": true,
  "data": {
    "metrics": {
      "activeCampaigns": 2,
      "investment": 1430.5,
      "leads": 98,
      "costPerLead": 14.6,
      "conversions": 11,
      "roas": 3.21,
      "currency": "BRL"
    },
    "accounts": [
      {
        "id": "ads_account_01J...",
        "provider": "meta",
        "name": "Genesys System",
        "status": "connected",
        "externalAccountId": "act_123456",
        "currency": "BRL",
        "lastSyncAt": "2026-09-01T12:00:00.000Z"
      }
    ],
    "campaigns": [
      {
        "id": "campaign_01J...",
        "name": "CormeX SC Setembro",
        "productName": "CormeX AI Agent",
        "objective": "leads",
        "channels": ["meta"],
        "status": "active",
        "budgetType": "daily",
        "budgetAmount": 50,
        "investment": 620,
        "leads": 43,
        "conversions": 5,
        "currency": "BRL",
        "startAt": "2026-09-01T00:00:00.000Z",
        "endAt": null,
        "updatedAt": "2026-09-01T12:00:00.000Z",
        "version": 4
      }
    ]
  },
  "meta": {
    "nextCursor": null,
    "correlationId": "req_01J..."
  }
}
```

Métricas sem base suficiente retornam `0`; o backend não inventa projeções. Coleções retornam `[]`, nunca `null`.

## 2. `v1-acquisition-campaign-get`

Carrega o detalhe e o formulário completo de uma campanha autorizada.

### Request

```json
{
  "workspaceId": "workspace_01J...",
  "campaignId": "campaign_01J..."
}
```

### Response

`data.campaign` contém os campos resumidos do overview e:

```json
{
  "providerCampaignIds": {
    "meta": "23851234567890123"
  },
  "input": {
    "name": "CormeX SC Setembro",
    "productName": "CormeX AI Agent",
    "productDescription": "Central de aquisição e vendas.",
    "offer": "Demonstração gratuita",
    "productUrl": "https://example.com/cormex",
    "mediaUrls": ["https://cdn.example.com/cormex.jpg"],
    "objective": "leads",
    "channels": ["meta"],
    "audience": {
      "locations": ["Santa Catarina"],
      "ageMin": 25,
      "ageMax": 55,
      "interests": ["software empresarial"],
      "broad": true
    },
    "budget": {
      "type": "daily",
      "amount": 50,
      "currency": "BRL"
    },
    "startAt": "2026-09-01T00:00:00.000Z",
    "endAt": null,
    "creative": {
      "headline": "Transforme sua operação comercial",
      "primaryText": "Centralize aquisição, atendimento e vendas.",
      "description": "Conheça o CormeX.",
      "callToAction": "LEARN_MORE"
    },
    "destination": {
      "type": "whatsapp",
      "url": "",
      "captureFields": ["name", "phone"],
      "consentText": ""
    },
    "automation": {
      "initialMessage": "Olá! Como posso ajudar?",
      "qualificationQuestions": ["Qual é o tamanho da sua equipe?"],
      "pipelineStageId": "new_lead",
      "tags": ["campaign", "meta"],
      "onlyRegisterLead": false
    }
  }
}
```

Campanha inexistente ou pertencente a outro workspace retorna `NOT_FOUND` sem revelar o tenant externo.

## 3. `v1-acquisition-campaign-upsert`

Cria ou atualiza rascunho. Ausência de `campaignId` significa criação. A mesma combinação de usuário, workspace e `clientRequestId` deve retornar a operação já concluída.

### Request

```json
{
  "workspaceId": "workspace_01J...",
  "campaignId": "campaign_01J...",
  "clientRequestId": "save:campaign_01J...:1725192000000",
  "campaign": {
    "name": "CormeX SC Setembro",
    "productName": "CormeX AI Agent",
    "objective": "leads",
    "channels": ["meta"],
    "audience": {},
    "budget": {},
    "creative": {},
    "destination": {},
    "automation": {},
    "expectedVersion": 4
  }
}
```

### Regras

- Novos registros iniciam em `draft` e `version = 1`.
- Atualização compara `expectedVersion`; divergência retorna `CONFLICT`.
- Rascunho aceita campos parciais, mas exige `name` e `productName` no primeiro salvamento.
- O servidor remove campos não autorizados e normaliza URLs, listas, datas, moeda e enums.
- A resposta retorna `data.campaign` completo com a nova versão.

## 4. `v1-acquisition-campaign-publish`

Executa a validação final e solicita publicação nos provedores.

### Request

```json
{
  "workspaceId": "workspace_01J...",
  "campaignId": "campaign_01J...",
  "expectedVersion": 5,
  "clientRequestId": "publish:campaign_01J...:1725192000000"
}
```

### Validações mínimas

- campanha no workspace e versão atual;
- conta ativa para cada canal;
- permissões e forma de pagamento válidas;
- produto, objetivo, público, região, orçamento, período, criativo e destino válidos;
- mídia compatível com o canal;
- limites do plano CormeX;
- autorização explícita registrada com usuário, data, versão e `correlationId`.

O backend pode devolver `preparing`, `review` ou `active`, conforme o processamento do provedor. Falha parcial informa o canal afetado sem expor token ou payload sensível.

## 5. `v1-acquisition-campaign-action`

Pausa, retoma, duplica ou encerra uma campanha.

### Request

```json
{
  "workspaceId": "workspace_01J...",
  "campaignId": "campaign_01J...",
  "action": "pause",
  "expectedVersion": 6,
  "clientRequestId": "pause:campaign_01J...:1725192000000"
}
```

`action` aceita `pause`, `resume`, `duplicate` ou `finish`.

- `pause`: somente campanha `active`.
- `resume`: somente campanha `paused`, após revalidar conta e cobrança.
- `duplicate`: cria outro registro `draft`, sem reutilizar IDs externos.
- `finish`: encerra nos provedores e não permite retomada.

A resposta retorna `data.campaign`. Em duplicação, esse campo contém a nova campanha.

## 6. `v1-acquisition-ai-suggest`

Gera uma sugestão editável para a seção de criativo. Não publica e não altera o orçamento.

### Request

```json
{
  "workspaceId": "workspace_01J...",
  "section": "creative",
  "clientRequestId": "ai:workspace_01J...:1725192000000",
  "campaign": {
    "productName": "CormeX AI Agent",
    "productDescription": "Central de aquisição e vendas.",
    "offer": "Demonstração gratuita",
    "objective": "leads",
    "channels": ["meta"],
    "audience": {
      "locations": ["Santa Catarina"]
    }
  }
}
```

### Response

```json
{
  "ok": true,
  "data": {
    "suggestion": {
      "headline": "Transforme sua operação comercial",
      "primaryText": "Capte, qualifique e acompanhe oportunidades em uma jornada única.",
      "description": "Conheça o CormeX AI Agent.",
      "callToAction": "LEARN_MORE",
      "rationale": "Texto direto para público empresarial.",
      "warnings": []
    }
  },
  "meta": {
    "correlationId": "req_01J..."
  }
}
```

O servidor aplica guardrails de alegações, políticas dos provedores, tamanho máximo e conteúdo proibido. Não retorna cadeia de pensamento, prompt interno nem credenciais do provedor de IA.

O front exige `headline` e `primaryText` não vazios. Falhas de configuração devem usar `AI_NOT_CONFIGURED`; falhas do provedor usam `AI_PROVIDER_ERROR`; respostas fora do contrato usam `AI_INVALID_RESPONSE`. Todos retornam mensagem acionável e `correlationId`.

## Automação do lead captado

Quando `campaign.automation.onlyRegisterLead=false`, cada lead confirmado pelo Google/Meta deve iniciar a jornada descrita em `docs/api/sales-automation-flow.md`: Lead idempotente, Conversation em `auto`, primeira abordagem, qualificação, Follow-ups e atualização de Pipeline. A função de publicação apenas persiste essa configuração; callbacks e workers executam a automação.

## Status da campanha

| Status | Significado |
| --- | --- |
| `draft` | Rascunho editável |
| `preparing` | Configuração em processamento |
| `review` | Pronta para revisão/publicação |
| `active` | Ativa no provedor |
| `paused` | Pausada |
| `finished` | Encerrada |
| `authorization_error` | Conta expirada ou permissão perdida |
| `publication_error` | Falha ao publicar |
| `payment_issue` | Problema de cobrança no provedor |

## Checklist do backend

- [ ] Implementar as seis Cloud Functions com nomes idênticos a `Endpoints`.
- [ ] Aplicar tenant guard, ACL e membership em toda leitura/mutação.
- [ ] Criar índice único para idempotência por workspace/usuário/operação.
- [ ] Persistir `version` e rejeitar sobrescrita concorrente.
- [ ] Guardar tokens Ads apenas em infraestrutura segura.
- [ ] Auditar publicação, alteração financeira, pausa, retomada e encerramento.
- [ ] Normalizar webhooks dos provedores e deduplicar eventos externos.
- [ ] Atribuir cada lead a `workspaceId`, `source=campaign` e `campaignId`.
- [ ] Acionar Conversas/Agente/Pipeline conforme a automação configurada.
- [ ] Agregar resultados no Dashboard sem duplicar métricas.
