# API da tela Pipeline de Vendas

Contrato da rota `/pipeline`, implementada por `PipelinePage`, `PipelineController` e `RemotePipelineRepository`. A tela não usa dados simulados: ao abrir ou atualizar, consulta diretamente o Cloud Code.

## Objetivo da tela

- carregar as cinco etapas do funil e todas as oportunidades autorizadas da empresa selecionada;
- mostrar totais, valores, busca e filtro por responsável;
- mover uma oportunidade com atualização otimista;
- confirmar o movimento no backend e desfazer a alteração visual se a API falhar.

## Transporte e segurança

Todas as funções usam `POST /functions/<nome>` e recebem `X-Parse-Session-Token`. O `workspaceId` enviado pelo aplicativo identifica a empresa solicitada, mas não concede acesso. O backend deve validar `request.user`, membership ativa e role em toda chamada.

## Etapas obrigatórias

`v1-pipeline-list` deve retornar as etapas nesta ordem e com IDs estáveis:

| ID | Nome | Posição | Cor sugerida |
| --- | --- | ---: | --- |
| `new_lead` | Novo lead | 0 | `#3B82F6` |
| `contacted` | Contato feito | 1 | `#06B6D4` |
| `proposal` | Proposta enviada | 2 | `#8B5CF6` |
| `negotiation` | Negociação | 3 | `#F3A712` |
| `closed` | Fechado | 4 | `#2FB67C` |

## DTO de oportunidade

```json
{
  "id": "opp_01J...",
  "workspaceId": "ws_01J...",
  "leadId": "lead_01J...",
  "stageId": "negotiation",
  "title": "Plano Enterprise",
  "companyName": "Empresa Exemplo",
  "contactName": "Marina Souza",
  "value": 45000.0,
  "probability": 70,
  "ownerId": "user_01J...",
  "ownerName": "Pedro Henrique",
  "product": "CormeX Enterprise",
  "source": "website",
  "outcome": "open",
  "lastInteractionAt": "2026-08-23T16:30:00.000Z",
  "nextActivityAt": "2026-08-26T13:00:00.000Z",
  "createdAt": "2026-08-20T12:00:00.000Z",
  "updatedAt": "2026-08-24T16:30:00.000Z"
}
```

Regras:

- IDs, `stageId`, título, empresa, contato, valor, probabilidade, origem, resultado e datas de criação/atualização são obrigatórios;
- `ownerId`, `ownerName`, `product`, `lastInteractionAt` e `nextActivityAt` podem ser `null`;
- `probability` é um inteiro entre 0 e 100 e `value` não pode ser negativo;
- `source`: `manual`, `import`, `website`, `whatsapp`, `instagram`, `referral` ou `campaign`;
- `outcome`: `open`, `won` ou `lost`;
- somente a etapa `closed` aceita `won` ou `lost`; todas as demais usam `open`;
- datas são ISO 8601 em UTC.

## 1. `v1-pipeline-list`

Request:

```json
{
  "workspaceId": "ws_01J..."
}
```

Response:

```json
{
  "ok": true,
  "data": {
    "stages": [
      {"id": "new_lead", "name": "Novo lead", "position": 0, "color": "#3B82F6"},
      {"id": "contacted", "name": "Contato feito", "position": 1, "color": "#06B6D4"},
      {"id": "proposal", "name": "Proposta enviada", "position": 2, "color": "#8B5CF6"},
      {"id": "negotiation", "name": "Negociação", "position": 3, "color": "#F3A712"},
      {"id": "closed", "name": "Fechado", "position": 4, "color": "#2FB67C"}
    ],
    "opportunities": [],
    "owners": [
      {"id": "user_01J...", "name": "Pedro Henrique"}
    ]
  },
  "meta": {
    "correlationId": "req_01J..."
  }
}
```

`owners` deve conter membros ativos que podem receber oportunidades. `opportunities` deve ser sempre um array, mesmo quando vazio. O front calcula os quatro cards de resumo a partir da resposta.

## 2. `v1-pipeline-move`

Request:

```json
{
  "workspaceId": "ws_01J...",
  "opportunityId": "opp_01J...",
  "fromStageId": "proposal",
  "toStageId": "negotiation",
  "outcome": "open"
}
```

Response:

```json
{
  "ok": true,
  "data": {
    "opportunity": {
      "id": "opp_01J...",
      "workspaceId": "ws_01J...",
      "leadId": "lead_01J...",
      "stageId": "negotiation",
      "title": "Plano Enterprise",
      "companyName": "Empresa Exemplo",
      "contactName": "Marina Souza",
      "value": 45000.0,
      "probability": 70,
      "ownerId": "user_01J...",
      "ownerName": "Pedro Henrique",
      "product": "CormeX Enterprise",
      "source": "website",
      "outcome": "open",
      "lastInteractionAt": "2026-08-23T16:30:00.000Z",
      "nextActivityAt": "2026-08-26T13:00:00.000Z",
      "createdAt": "2026-08-20T12:00:00.000Z",
      "updatedAt": "2026-08-24T18:00:00.000Z"
    }
  },
  "meta": {"correlationId": "req_01J..."}
}
```

Regras do backend:

1. buscar a oportunidade por `id + workspace` autorizado;
2. comparar a etapa atual com `fromStageId`;
3. se outro usuário já a moveu, devolver `CONFLICT` sem sobrescrever silenciosamente;
4. validar a combinação `toStageId + outcome`;
5. persistir a alteração e um evento de auditoria na mesma operação lógica;
6. devolver sempre o DTO completo e atualizado.

O evento recomendado é `OpportunityStageChanged`, com oportunidade, workspace, etapa anterior, nova etapa, resultado, usuário responsável e data do servidor.

## Erros esperados

| Código | Comportamento |
| --- | --- |
| `UNAUTHENTICATED` | Sessão inválida; o aplicativo encerra o acesso. |
| `FORBIDDEN` | Membership ou role sem permissão. |
| `WORKSPACE_NOT_FOUND` | Empresa não acessível. |
| `NOT_FOUND` | Oportunidade ausente dentro do tenant autorizado. |
| `VALIDATION_ERROR` | Etapa, resultado ou payload inválido. |
| `CONFLICT` | `fromStageId` não corresponde mais ao estado salvo; o front faz rollback. |
| `PLAN_LIMIT_REACHED` | Limite comercial do plano atingido. |
| `INTERNAL_ERROR` | Falha inesperada com `correlationId`. |

## Arquivos Flutter

- `lib/Src/Features/pipeline/presentation/pages/pipeline_page.dart`
- `lib/Src/Features/pipeline/presentation/controllers/pipeline_controller.dart`
- `lib/Src/Features/pipeline/data/remote_pipeline_repository.dart`
- `lib/Src/Shared/models/pipeline_models.dart`

