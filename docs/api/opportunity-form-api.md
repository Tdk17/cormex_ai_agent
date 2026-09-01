# API das telas Nova e Editar Oportunidade

Contrato das rotas `/pipeline/new` e `/pipeline/:opportunityId/edit`. O formulário consulta leads reais, etapas e responsáveis e grava diretamente no Cloud Code.

## Dependências ao abrir a tela

1. `v1-pipeline-list` fornece etapas, oportunidades atuais e responsáveis atribuíveis. Consulte [API da tela Pipeline](pipeline-board-api.md).
2. `v1-leads-list` fornece o lead que será vinculado. Consulte [API de Leads](../leads-api.md).
3. Na edição, se a oportunidade não estiver no cache do pipeline, `v1-pipeline-get` carrega os dados atuais.
4. Se o lead vinculado não estiver entre os 100 primeiros, `v1-leads-get` carrega esse lead para manter o formulário editável.

Request de leads usado pelo formulário:

```json
{
  "workspaceId": "ws_01J...",
  "limit": 100
}
```

Toda oportunidade deve estar vinculada a um `leadId` do mesmo workspace.

## Payload editável

```json
{
  "leadId": "lead_01J...",
  "stageId": "new_lead",
  "title": "Plano Enterprise",
  "companyName": "Empresa Exemplo",
  "contactName": "Marina Souza",
  "value": 45000.0,
  "probability": 20,
  "ownerId": "user_01J...",
  "ownerName": "Pedro Henrique",
  "product": "CormeX Enterprise",
  "source": "website",
  "outcome": "open",
  "nextActivityAt": "2026-08-26T13:00:00.000Z"
}
```

Campos nulos permitidos: `ownerId`, `ownerName`, `product` e `nextActivityAt`. O backend deve resolver e validar `ownerName` a partir de `ownerId`; nunca deve confiar no nome enviado para autorização ou integridade.

## 1. `v1-pipeline-create`

Request:

```json
{
  "workspaceId": "ws_01J...",
  "opportunity": {
    "leadId": "lead_01J...",
    "stageId": "new_lead",
    "title": "Plano Enterprise",
    "companyName": "Empresa Exemplo",
    "contactName": "Marina Souza",
    "value": 45000.0,
    "probability": 20,
    "ownerId": null,
    "ownerName": null,
    "product": "CormeX Enterprise",
    "source": "manual",
    "outcome": "open",
    "nextActivityAt": null
  }
}
```

Response: `data.opportunity` com o DTO completo especificado na [API da tela Pipeline](pipeline-board-api.md).

## 2. `v1-pipeline-update`

Request:

```json
{
  "workspaceId": "ws_01J...",
  "opportunityId": "opp_01J...",
  "changes": {
    "leadId": "lead_01J...",
    "stageId": "proposal",
    "title": "Plano Enterprise anual",
    "companyName": "Empresa Exemplo",
    "contactName": "Marina Souza",
    "value": 50000.0,
    "probability": 60,
    "ownerId": "user_01J...",
    "ownerName": "Pedro Henrique",
    "product": "CormeX Enterprise",
    "source": "website",
    "outcome": "open",
    "nextActivityAt": "2026-08-26T13:00:00.000Z"
  }
}
```

O front envia o estado editável completo. Um campo nullable com `null` limpa o valor anterior. O backend não pode alterar `workspaceId`, identidade, `createdAt` ou eventos históricos pelo payload do cliente.

Response: `data.opportunity` completo e atualizado.

## Validações obrigatórias do backend

- usuário autenticado e membro ativo do workspace;
- lead existente e pertencente ao mesmo workspace;
- título, empresa e contato com pelo menos dois caracteres;
- valor maior ou igual a zero;
- probabilidade inteira entre 0 e 100;
- etapa pertencente ao pipeline do workspace;
- responsável ativo e autorizável dentro da empresa;
- origem dentro do enum documentado;
- `closed` exige `won` ou `lost`; qualquer outra etapa exige `open`;
- aplicar limites do plano antes da criação;
- atualizar datas pelo relógio do servidor;
- criar evento de auditoria para criação e alteração relevante.

## Erros esperados

`UNAUTHENTICATED`, `FORBIDDEN`, `WORKSPACE_NOT_FOUND`, `NOT_FOUND`, `VALIDATION_ERROR`, `CONFLICT`, `PLAN_LIMIT_REACHED`, `RATE_LIMITED` e `INTERNAL_ERROR`.

## Arquivos Flutter

- `lib/Src/Features/pipeline/presentation/pages/opportunity_form_page.dart`
- `lib/Src/Features/pipeline/presentation/controllers/opportunity_form_controller.dart`
- `lib/Src/Features/pipeline/domain/opportunity_input.dart`
- `lib/Src/Features/pipeline/data/remote_pipeline_repository.dart`
