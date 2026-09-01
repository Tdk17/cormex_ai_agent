# API da tela Dashboard

Contrato da rota `/dashboard`, implementada por `DashboardPage`, `DashboardController` e `RemoteDashboardRepository`. Todos os números, variações, etapas e conversas exibidos devem vir da função `v1-dashboard-metrics`; a tela não contém registros comerciais fixos.

## `v1-dashboard-metrics`

Request:

```json
{
  "workspaceId": "ws_01J...",
  "period": "30d"
}
```

`period` aceita `7d`, `30d` ou `90d`.

Response:

```json
{
  "ok": true,
  "data": {
    "totalLeads": 128,
    "activeConversations": 17,
    "qualifiedLeads": 43,
    "openOpportunities": 26,
    "conversions": 12,
    "conversionRate": 9.4,
    "changes": {
      "totalLeads": "+12,4%",
      "activeConversations": "+8,1%",
      "qualifiedLeads": "+15,7%",
      "conversionRate": "+2,3 p.p."
    },
    "funnel": {
      "Novo lead": 52,
      "Contato feito": 31,
      "Proposta enviada": 20,
      "Negociação": 13,
      "Fechado": 12
    },
    "recentConversations": [
      {
        "id": "conversation_01J...",
        "leadName": "Marina Souza",
        "lastMessage": "Quero entender os planos.",
        "lastMessageAt": "2026-08-24T21:30:00.000Z",
        "unreadCount": 2
      }
    ],
    "hasConnectedChannel": true
  },
  "meta": {
    "correlationId": "req_01J..."
  }
}
```

## Regras do backend

- exigir `request.user` e membership ativa no workspace;
- calcular os indicadores somente com objetos do tenant autorizado;
- usar o mesmo intervalo temporal para métricas e variações;
- retornar `changes` vazio quando não houver período anterior comparável;
- limitar `recentConversations` às conversas autorizadas mais recentes;
- não retornar conteúdo sensível, credenciais de canais ou mensagens internas;
- devolver arrays e mapas vazios quando a empresa ainda não possuir dados;
- usar ISO 8601 UTC em `lastMessageAt`;
- gerar `correlationId` em sucesso e erro.

## Estado vazio

Quando todos os indicadores forem zero e `recentConversations` estiver vazio, o Flutter exibe o estado inicial da empresa. Nenhum valor de demonstração é inserido pelo aplicativo.

## Erros esperados

`UNAUTHENTICATED`, `FORBIDDEN`, `WORKSPACE_NOT_FOUND`, `VALIDATION_ERROR`, `RATE_LIMITED` e `INTERNAL_ERROR`.

## Arquivos Flutter

- `lib/Src/Features/dashboard/presentation/pages/dashboard_page.dart`
- `lib/Src/Features/dashboard/presentation/controllers/dashboard_controller.dart`
- `lib/Src/Features/dashboard/data/remote_dashboard_repository.dart`
- `lib/Src/Shared/models/dashboard_metrics_model.dart`

