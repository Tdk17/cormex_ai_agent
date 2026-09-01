# API da tela Caixa de Entrada de Conversas

Contrato da rota `/conversations`, implementada por `ConversationsPage`, `ConversationsController` e `RemoteConversationsRepository`. A tela consulta somente o Cloud Code: não há lista local, resposta de demonstração nem fallback que permita operar sem backend.

## Objetivo da tela

- listar conversas do workspace selecionado, ordenadas pela atividade mais recente;
- buscar por lead ou conteúdo indexado;
- filtrar por canal, status e responsável;
- mostrar mensagens não lidas, modo de atendimento e resumo da última mensagem;
- paginar por cursor e atualizar a lista sem duplicar itens.

## Transporte e autorização

Todas as chamadas usam `POST /functions/<nome>`, `X-Parse-Application-Id` e `X-Parse-Session-Token`. O `workspaceId` nunca concede acesso por si só: cada função deve exigir `request.user`, localizar uma membership ativa e restringir todas as consultas ao tenant autorizado.

## DTO de conversa

```json
{
  "id": "conversation_01J...",
  "workspaceId": "ws_01J...",
  "lead": {
    "id": "lead_01J...",
    "name": "Marina Souza"
  },
  "channel": "whatsapp",
  "status": "waiting_customer",
  "agentMode": "assist",
  "assignedUser": {
    "id": "user_01J...",
    "name": "Pedro Henrique"
  },
  "lastMessage": {
    "preview": "Vou analisar a proposta.",
    "sentAt": "2026-08-24T21:30:00.000Z"
  },
  "unreadCount": 2,
  "updatedAt": "2026-08-24T21:30:00.000Z"
}
```

Campos e enums:

- `id`, `workspaceId`, `lead`, `channel`, `status`, `agentMode`, `unreadCount` e `updatedAt` são obrigatórios;
- `assignedUser` e `lastMessage` podem ser `null` quando ainda não existirem;
- `channel`: `whatsapp`, `instagram`, `webchat` ou `email`;
- `status`: `open`, `waiting_customer` ou `closed`;
- `agentMode`: `auto`, `assist` ou `human`;
- datas são ISO 8601 em UTC. Também são aceitos objetos Date do Parse com `{ "__type": "Date", "iso": "..." }`;
- `unreadCount` deve ser inteiro maior ou igual a zero;
- `lastMessage.preview` deve ser sanitizado e limitado pelo backend para não carregar anexos ou payloads completos na lista.

## `v1-conversations-list`

Request inicial:

```json
{
  "workspaceId": "ws_01J...",
  "search": "marina",
  "channel": "whatsapp",
  "status": "open",
  "assignedUserId": "user_01J...",
  "limit": 30
}
```

Todos os filtros são opcionais. Para a página seguinte, o front repete os filtros e acrescenta o cursor opaco recebido:

```json
{
  "workspaceId": "ws_01J...",
  "status": "open",
  "cursor": "eyJ1cGRhdGVkQXQiOiIyMDI2...",
  "limit": 30
}
```

Response:

```json
{
  "ok": true,
  "data": {
    "items": [],
    "owners": [
      {"id": "user_01J...", "name": "Pedro Henrique"}
    ]
  },
  "meta": {
    "correlationId": "req_01J...",
    "nextCursor": null
  }
}
```

Regras do backend:

1. ordenar por `updatedAt DESC` e usar um desempate estável por `objectId DESC`;
2. criar um cursor opaco com os valores da última linha; não usar offset;
3. aplicar os mesmos filtros antes de calcular a página seguinte;
4. buscar somente campos necessários para a lista e impedir N+1 ao resolver lead e responsável;
5. limitar `limit` entre 1 e 100, usando 30 como padrão;
6. retornar `items: []` e `nextCursor: null` no estado vazio;
7. retornar em `owners` apenas membros ativos que podem receber uma conversa;
8. pesquisar somente dados do workspace autorizado;
9. gerar `correlationId` em sucesso e erro.

## Estados de interface

- `loading`: carregamento central quando não há cache e barra linear durante atualização;
- `success`: lista com seleção, canal, modo, status e não lidas;
- `empty`: nenhum item após aplicar os filtros;
- `error`: mensagem normalizada e `correlationId`, com tentativa manual;
- paginação: disparada próximo ao final e protegida contra chamadas simultâneas.

## Erros esperados

`UNAUTHENTICATED`, `FORBIDDEN`, `WORKSPACE_NOT_FOUND`, `VALIDATION_ERROR`, `RATE_LIMITED` e `INTERNAL_ERROR`.

## Arquivos Flutter

- `lib/Src/Features/conversations/presentation/pages/conversations_page.dart`
- `lib/Src/Features/conversations/presentation/widgets/conversation_list_panel.dart`
- `lib/Src/Features/conversations/presentation/controllers/conversations_controller.dart`
- `lib/Src/Features/conversations/data/remote_conversations_repository.dart`
