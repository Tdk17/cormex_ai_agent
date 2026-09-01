# API da tela Console de Teste do Agente

Contrato da rota `/agent/test`, implementada por `AgentTestPage`, `AgentTestController` e `RemoteAgentRepository`. O console é um sandbox: deve produzir uma resposta estruturada para avaliação, sem criar conversa real, persistir mensagem comercial ou chamar um adapter de entrega externo.

## Objetivo da tela

- informar um lead e contexto controlados;
- simular uma conversa usando a última configuração salva;
- mostrar a resposta exata gerada pelo backend;
- explicar produto consultado, regras utilizadas, ação sugerida e warnings;
- indicar quando a IA recomenda transferência humana;
- mostrar uso técnico opcional sem expor provider ou credenciais;
- preservar o texto digitado em erro e impedir requisições simultâneas.

## `v1-agent-test-reply`

Request:

```json
{
  "workspaceId": "ws_01J...",
  "message": "Somos 12 vendedores. Quanto custa e como funciona a implantação?",
  "lead": {
    "name": "Marina Souza",
    "company": "Empresa Exemplo",
    "phone": "+5511999999999",
    "email": "marina@empresa.com"
  },
  "context": {
    "productInterest": "CormeX Enterprise",
    "notes": "Precisa decidir até sexta-feira."
  },
  "history": [
    {
      "role": "user",
      "content": "Quero automatizar o atendimento comercial."
    },
    {
      "role": "assistant",
      "content": "Quantas pessoas fazem parte da sua equipe?"
    }
  ],
  "clientRequestId": "agent_test_1787650000000000_0"
}
```

Campos:

- `workspaceId`, `message`, `lead.name` e `clientRequestId` são obrigatórios;
- `message`: 1 a 4.000 caracteres;
- `lead.company`, `lead.phone` e `lead.email` são opcionais;
- `context.productInterest` e `context.notes` são opcionais;
- `context.notes`: máximo de 2.000 caracteres;
- `history`: no máximo 20 itens, apenas `user` e `assistant`, na ordem cronológica;
- o backend deve descartar campos não permitidos em vez de incorporá-los ao prompt;
- `clientRequestId` é usado para idempotência de geração e contabilização.

Response:

```json
{
  "ok": true,
  "data": {
    "reply": {
      "content": "Para uma equipe de 12 vendedores, o plano Enterprise centraliza os atendimentos e permite implantação assistida. Posso preparar uma proposta detalhada para sua empresa.",
      "productConsulted": "CormeX Enterprise",
      "rulesUsed": [
        "Nunca inventar preço, prazo ou desconto.",
        "Qualificar o tamanho da equipe antes de avançar."
      ],
      "suggestedAction": "Solicitar telefone e agendar uma demonstração",
      "warnings": [
        "O preço final precisa ser confirmado por um vendedor."
      ],
      "shouldHandoff": false
    },
    "usage": {
      "inputTokens": 820,
      "outputTokens": 96,
      "totalTokens": 916,
      "latencyMs": 1240
    }
  },
  "meta": {
    "correlationId": "req_01J..."
  }
}
```

`usage` é opcional. Não devolver nome interno do provider, API key, cadeia de pensamento, prompt de sistema ou credenciais.

## Pipeline obrigatório do backend

1. autenticar usuário e validar membership no workspace;
2. validar permissão para testar o agente;
3. carregar a última configuração persistida e sua versão;
4. carregar somente conhecimento autorizado para o agente/workspace;
5. normalizar lead, contexto e histórico;
6. construir o prompt no backend usando configuração, políticas e guardrails;
7. aplicar rate limit e limite do plano antes de chamar o provider;
8. gerar a resposta pelo adapter de IA configurado;
9. validar tamanho, conteúdo proibido, preço, dados pessoais e transferência;
10. produzir o DTO estruturado de `reply`;
11. contabilizar uso uma única vez por `workspaceId + clientRequestId`;
12. devolver `correlationId` sem acionar WhatsApp, e-mail, CRM ou outro canal.

## Idempotência

Se o cliente repetir exatamente a mesma chamada após timeout, o backend deve devolver o resultado já associado ao `clientRequestId` ou concluir a geração pendente sem contabilizar duas vezes. O controller reutiliza o mesmo identificador quando mensagem, lead, contexto e histórico não mudaram depois de uma falha ambígua.

## Regras do sandbox

- pode testar um agente inativo, desde que a configuração exista e o usuário tenha permissão;
- não criar `Conversation`, `Message`, oportunidade, tarefa ou follow-up;
- não chamar adapter de envio externo;
- não alterar score/status do lead informado;
- dados de teste não devem virar uma base comercial real;
- aplicar as mesmas políticas de conteúdo utilizadas em produção;
- marcar claramente quando `shouldHandoff` for `true`;
- cada warning deve ser curto, acionável e seguro para exibição ao usuário.

## Estados da interface

- vazio: instrução para preencher o lead e iniciar o teste;
- enviando: composer bloqueado e indicador de processamento;
- sucesso: conversa local e diagnóstico estruturado da resposta;
- erro: rascunho preservado, mensagem normalizada e `correlationId`;
- limpar: remove apenas o histórico local da sessão de teste.

## Erros esperados

| Código | Situação |
| --- | --- |
| `UNAUTHENTICATED` | sessão inválida |
| `FORBIDDEN` | usuário sem permissão de teste |
| `WORKSPACE_NOT_FOUND` | tenant não acessível |
| `NOT_FOUND` | agente ainda não configurado |
| `VALIDATION_ERROR` | lead, contexto, histórico ou mensagem inválida |
| `PLAN_LIMIT_REACHED` | consumo contratado esgotado |
| `RATE_LIMITED` | excesso de testes |
| `AI_PROVIDER_ERROR` | provider não gerou resposta válida |
| `INTERNAL_ERROR` | falha inesperada com `correlationId` |

## Arquivos Flutter

- `lib/Src/Features/agent/presentation/pages/agent_test_page.dart`
- `lib/Src/Features/agent/presentation/controllers/agent_test_controller.dart`
- `lib/Src/Features/agent/domain/agent_test_request.dart`
- `lib/Src/Features/agent/data/remote_agent_repository.dart`

