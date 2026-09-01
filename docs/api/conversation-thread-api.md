# API da tela Atendimento da Conversa

Contrato da rota `/conversations/:conversationId`, implementada pelo painel central de chat e pelo painel de contexto do lead. A tela lê e grava diretamente pelas funções `v1-conversations-get`, `v1-conversations-send-message`, `v1-conversations-assign` e `v1-conversations-set-mode`.

`v1-conversations-delivery-webhook` é exclusiva do provedor/worker no backend. Ela não é chamada pelo Flutter, não pertence ao `Endpoints` do aplicativo e deve validar assinatura e idempotência antes de atualizar o status persistido da mensagem.

## Comportamento funcional

- carrega conversa, lead, contexto comercial, responsáveis e mensagens;
- pagina mensagens antigas quando o usuário alcança o início da thread;
- mantém o texto digitado ao atualizar a API e só o apaga após confirmação de envio;
- impede dois envios simultâneos;
- diferencia visualmente cliente, atendente humano, IA e eventos do sistema;
- permite assumir o atendimento, devolver para a IA, trocar modo e responsável;
- em telas largas exibe lista, chat e contexto em três painéis; no celular usa rotas e painel inferior.

## DTO de mensagem

```json
{
  "id": "message_01J...",
  "conversationId": "conversation_01J...",
  "direction": "outbound",
  "senderType": "human",
  "senderName": "Pedro Henrique",
  "type": "text",
  "content": "Posso esclarecer mais algum ponto?",
  "status": "sent",
  "sentAt": "2026-08-24T21:35:00.000Z"
}
```

- `direction`: `inbound` ou `outbound`;
- `senderType`: `lead`, `human`, `ai` ou `system`;
- `type`: neste marco o composer envia `text`; o backend pode devolver tipos adicionais, mantendo `content` legível;
- `status`: `queued`, `sent`, `delivered`, `read` ou `failed`;
- `senderName` é opcional;
- `content` é obrigatório, sanitizado, e deve respeitar o limite de 4.000 caracteres para texto;
- `sentAt` deve ser a data do servidor em UTC.

## DTO de lead

`v1-conversations-get` deve retornar o mesmo DTO completo documentado em `docs/leads-api.md`, incluindo `id`, `workspaceId`, nome, telefone, e-mail, empresa, origem, status, tags, responsável, score e datas.

## 1. `v1-conversations-get`

Request inicial:

```json
{
  "workspaceId": "ws_01J...",
  "conversationId": "conversation_01J...",
  "messagesLimit": 50,
  "markAsRead": true
}
```

Request para mensagens anteriores:

```json
{
  "workspaceId": "ws_01J...",
  "conversationId": "conversation_01J...",
  "messagesCursor": "eyJzZW50QXQiOiIyMDI2...",
  "messagesLimit": 50,
  "markAsRead": false
}
```

Response:

```json
{
  "ok": true,
  "data": {
    "conversation": {
      "id": "conversation_01J...",
      "workspaceId": "ws_01J...",
      "lead": {"id": "lead_01J...", "name": "Marina Souza"},
      "channel": "whatsapp",
      "status": "open",
      "agentMode": "assist",
      "assignedUser": null,
      "lastMessage": {
        "preview": "Gostaria de conhecer os planos.",
        "sentAt": "2026-08-24T21:30:00.000Z"
      },
      "unreadCount": 0,
      "updatedAt": "2026-08-24T21:30:00.000Z"
    },
    "messages": [],
    "lead": {
      "id": "lead_01J...",
      "workspaceId": "ws_01J...",
      "name": "Marina Souza",
      "phone": "+5511999999999",
      "email": "marina@empresa.com",
      "company": "Empresa Exemplo",
      "source": "whatsapp",
      "status": "qualified",
      "tags": ["enterprise", "quente"],
      "ownerId": null,
      "score": 82,
      "lastContactAt": "2026-08-24T21:30:00.000Z",
      "createdAt": "2026-08-20T12:00:00.000Z",
      "updatedAt": "2026-08-24T21:30:00.000Z"
    },
    "context": {
      "product": "CormeX Enterprise",
      "cartSummary": "12 licenças — R$ 1.490/mês",
      "historySummary": "Solicitou proposta e perguntou sobre implantação.",
      "notes": "Prefere contato no período da tarde."
    },
    "owners": [
      {"id": "user_01J...", "name": "Pedro Henrique"}
    ],
    "suggestedReply": "Claro! Posso detalhar a implantação para sua equipe.",
    "nextMessagesCursor": null
  },
  "meta": {
    "correlationId": "req_01J...",
    "nextCursor": null
  }
}
```

Regras:

- validar a conversa por `conversationId + workspaceId` autorizado antes de buscar mensagens;
- ordenar cada página de mensagens do mais antigo para o mais novo na resposta;
- o cursor de mensagens deve buscar itens anteriores ao primeiro item já carregado;
- quando `markAsRead` for `true`, zerar de forma idempotente as não lidas destinadas ao usuário atual;
- `suggestedReply` só deve existir no modo `assist`; pode ser `null`;
- o contexto nunca deve conter segredos, credenciais de canal ou instruções internas do agente.

## 2. `v1-conversations-send-message`

Request:

```json
{
  "workspaceId": "ws_01J...",
  "conversationId": "conversation_01J...",
  "content": "Posso esclarecer mais algum ponto?",
  "type": "text",
  "clientRequestId": "flutter_conversation_01J..._1787600000000000_0"
}
```

Response:

```json
{
  "ok": true,
  "data": {
    "message": {},
    "conversation": {}
  },
  "meta": {"correlationId": "req_01J..."}
}
```

`message` e `conversation` devem ser os DTOs completos e persistidos. Regras obrigatórias:

1. criar índice único lógico por `workspaceId + clientRequestId`;
2. repetir a mesma request deve devolver a mensagem já criada, nunca enviar duas vezes ao canal;
3. validar conversa aberta, conteúdo, permissão e conexão do canal;
4. o usuário autenticado deve ser registrado como remetente quando o modo for humano/assistido;
5. persistir a mensagem antes de solicitar entrega ao provedor e atualizar `status` conforme o processamento;
6. atualizar preview, data e ordenação da conversa;
7. responder somente depois de existir uma mensagem identificável;
8. webhooks de entrega devem ser idempotentes e validar assinatura.

Se uma resposta de rede falhar de forma ambígua, o controller reutiliza o mesmo `clientRequestId` enquanto o conteúdo do composer permanecer igual. Um novo identificador só é criado quando o texto muda ou o envio anterior é confirmado.

## 3. `v1-conversations-assign`

Assumir ou transferir:

```json
{
  "workspaceId": "ws_01J...",
  "conversationId": "conversation_01J...",
  "userId": "user_01J..."
}
```

Remover responsável:

```json
{
  "workspaceId": "ws_01J...",
  "conversationId": "conversation_01J...",
  "userId": null
}
```

Response: `{ "ok": true, "data": { "conversation": {} } }`, sempre com o DTO completo.

O backend deve verificar se o usuário de destino possui membership ativa, aplicar as regras de role e criar um evento imutável `ConversationAssigned` com responsável anterior, novo responsável, ator e data do servidor.

## 4. `v1-conversations-set-mode`

Request:

```json
{
  "workspaceId": "ws_01J...",
  "conversationId": "conversation_01J...",
  "mode": "human"
}
```

Response: `{ "ok": true, "data": { "conversation": {} } }`, sempre com o DTO completo.

Semântica dos modos:

| Modo | Comportamento obrigatório |
| --- | --- |
| `auto` | a IA pode elaborar e enviar respostas conforme as regras ativas; atendimento humano não fica atribuído após “devolver para IA” |
| `assist` | a IA cria `suggestedReply`, mas somente um usuário envia ao canal |
| `human` | suspende imediatamente respostas automáticas e mantém o responsável humano |

Toda alteração deve criar `ConversationModeChanged`. Ao assumir, o front executa `assign(userAtual)` e depois `setMode(human)`. Ao devolver, executa `setMode(auto)` e depois `assign(null)`. As funções precisam ser idempotentes; se uma etapa falhar, a atualização manual da thread reconcilia o estado retornado pelo servidor.

## Concorrência e segurança

- impedir que jobs da IA enviem após o modo mudar para `human`; conferir o modo novamente imediatamente antes da entrega;
- usar lock, versão ou transação lógica ao alterar atribuição/modo;
- nunca aceitar `workspaceId`, `userId` ou `conversationId` sem validar as relações no servidor;
- não expor access tokens, prompts internos ou payload bruto de provedor;
- rate-limit por usuário, workspace e conversa;
- registrar auditoria de envio, atribuição, mudança de modo e falha externa.

## Erros esperados

| Código | Uso |
| --- | --- |
| `UNAUTHENTICATED` | sessão ausente ou expirada |
| `FORBIDDEN` | membership/role sem permissão |
| `WORKSPACE_NOT_FOUND` | tenant não acessível |
| `NOT_FOUND` | conversa, lead ou responsável ausente no tenant |
| `VALIDATION_ERROR` | conteúdo, modo, cursor ou tipo inválido |
| `CONFLICT` | conversa encerrada ou versão concorrente |
| `INTEGRATION_NOT_CONNECTED` | canal ainda não conectado |
| `AI_PROVIDER_ERROR` | falha ao gerar sugestão |
| `EXTERNAL_PROVIDER_ERROR` | falha do canal ao enfileirar/enviar |
| `RATE_LIMITED` | excesso de chamadas |
| `INTERNAL_ERROR` | falha inesperada com `correlationId` |

## Arquivos Flutter

- `lib/Src/Features/conversations/presentation/widgets/conversation_thread_panel.dart`
- `lib/Src/Features/conversations/presentation/widgets/lead_context_panel.dart`
- `lib/Src/Features/conversations/presentation/controllers/conversation_thread_controller.dart`
- `lib/Src/Features/conversations/data/remote_conversations_repository.dart`
- `lib/Src/Shared/models/conversation_models.dart`
