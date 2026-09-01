# API da tela Detalhes da Oportunidade

Contrato da rota `/pipeline/:opportunityId`, implementada por `OpportunityDetailPage` e `OpportunityDetailController`.

## `v1-pipeline-get`

Request:

```json
{
  "workspaceId": "ws_01J...",
  "opportunityId": "opp_01J..."
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
      "updatedAt": "2026-08-24T16:30:00.000Z"
    }
  },
  "meta": {
    "correlationId": "req_01J..."
  }
}
```

A especificação completa do DTO está em [API da tela Pipeline](pipeline-board-api.md).

## Comportamento do front

- apresenta imediatamente o item em memória quando veio do Kanban;
- consulta `v1-pipeline-get` para confirmar os dados atuais;
- atualiza também o estado central do Pipeline após a resposta;
- oferece navegação para edição e para o lead vinculado;
- exibe empresa, contato, produto, responsável, origem, etapa, resultado, valor, probabilidade, datas e tempo sem interação;
- mostra o `correlationId` quando a API devolve erro.

## Regras obrigatórias do backend

1. validar sessão e membership antes da consulta;
2. filtrar simultaneamente por `opportunityId` e workspace autorizado;
3. devolver `NOT_FOUND` tanto para ID inexistente quanto para objeto de outro tenant;
4. não retornar notas privadas, credenciais, ACLs internas ou segredos de integrações;
5. preencher `ownerName` e dados derivados somente a partir de objetos autorizados;
6. manter datas em UTC e o DTO estável.

## Erros esperados

| Código | Quando usar |
| --- | --- |
| `UNAUTHENTICATED` | Sessão ausente ou expirada. |
| `FORBIDDEN` | Usuário sem membership/role adequada. |
| `WORKSPACE_NOT_FOUND` | Empresa solicitada não acessível. |
| `NOT_FOUND` | Oportunidade não encontrada no workspace autorizado. |
| `INTERNAL_ERROR` | Falha inesperada, sempre com `correlationId`. |

## Arquivos Flutter

- `lib/Src/Features/pipeline/presentation/pages/opportunity_detail_page.dart`
- `lib/Src/Features/pipeline/presentation/controllers/opportunity_detail_controller.dart`
- `lib/Src/Features/pipeline/data/remote_pipeline_repository.dart`
- `lib/Src/Shared/models/pipeline_models.dart`

