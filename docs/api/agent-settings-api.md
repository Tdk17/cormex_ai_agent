# API da tela Configuração do Agente de IA

Contrato da rota `/agent`, implementada por `AgentSettingsPage`, `AgentSettingsController` e `RemoteAgentRepository`. A tela não contém configuração comercial simulada: carrega `v1-agent-get` e persiste somente pela função `v1-agent-update`.

## Responsabilidade da tela

- configurar identidade, objetivo, persona e tom de voz;
- definir produto/oferta e mensagem inicial;
- registrar regras obrigatórias e perguntas de qualificação;
- escolher `auto`, `assist` ou `human`;
- controlar ativação, dias, horários e fuso;
- configurar limites de resposta, coleta de dados, preço, follow-up e transferência humana;
- salvar com controle de versão para não sobrescrever outra sessão silenciosamente.

O Flutter edita a configuração funcional. Prompt de sistema final, recuperação de conhecimento, provider/modelo, credenciais, guardrails definitivos, autorização e contabilização de uso pertencem ao backend.

## Transporte e segurança

As funções usam `POST /functions/<nome>`, `X-Parse-Application-Id` e `X-Parse-Session-Token`. O backend deve:

1. exigir `request.user` autenticado;
2. validar membership ativa no `workspaceId`;
3. permitir mutação somente aos papéis autorizados, recomendados `owner` e `admin`;
4. restringir leitura conforme política do workspace;
5. nunca devolver API key, prompt interno compilado, access token ou credencial do provider;
6. registrar ator, versão anterior, nova versão, data e `correlationId`.

## DTO `SalesAgent`

```json
{
  "id": "agent_01J...",
  "workspaceId": "ws_01J...",
  "name": "Clara",
  "objective": "Qualificar leads e conduzir os contatos prontos para uma proposta.",
  "persona": "Consultora comercial experiente, clara e respeitosa.",
  "tone": "consultive",
  "mode": "assist",
  "productOffer": "CormeX Enterprise para equipes comerciais, a partir de R$ 1.490/mês.",
  "initialMessage": "Olá! Sou a Clara. Posso entender o que sua equipe precisa?",
  "isActive": true,
  "rules": [
    "Nunca inventar preço, prazo ou desconto.",
    "Transferir para um humano quando o cliente solicitar."
  ],
  "qualificationQuestions": [
    "Quantas pessoas fazem parte da equipe comercial?",
    "Qual é o principal problema que desejam resolver?"
  ],
  "schedule": {
    "enabled": true,
    "timezone": "America/Sao_Paulo",
    "daysOfWeek": [1, 2, 3, 4, 5],
    "startTime": "08:00",
    "endTime": "18:00"
  },
  "policies": {
    "maxResponseCharacters": 700,
    "maxAttemptsBeforeHandoff": 3,
    "askForName": true,
    "askForPhone": true,
    "allowPricePresentation": true,
    "allowFollowUp": true,
    "followUpDelayMinutes": 1440,
    "handoffOnRequest": true
  },
  "version": 4,
  "updatedAt": "2026-08-25T14:00:00.000Z"
}
```

### Enums e formatos

- `tone`: `consultive`, `friendly`, `direct`, `formal` ou `persuasive`;
- `mode`: `auto`, `assist` ou `human`;
- `daysOfWeek`: ISO-8601, onde `1` é segunda-feira e `7` é domingo;
- `startTime` e `endTime`: `HH:mm` em 24 horas;
- `timezone`: identificador IANA, nunca offset fixo;
- `version`: inteiro crescente controlado pelo servidor;
- datas em ISO 8601 UTC ou objeto Date do Parse.

### Semântica dos modos

| Modo | Comportamento |
| --- | --- |
| `auto` | A IA pode gerar e enviar uma resposta somente depois de passar pelos guardrails e pelas regras atuais. |
| `assist` | A IA gera um rascunho; um usuário precisa confirmar o envio. |
| `human` | A IA não responde nem agenda envio automático; a equipe conduz a conversa. |

`isActive: false` suspende novas ações do agente independentemente do modo. A função de sandbox pode continuar disponível para usuários autorizados.

## 1. `v1-agent-get`

Request:

```json
{
  "workspaceId": "ws_01J..."
}
```

Response com configuração:

```json
{
  "ok": true,
  "data": {
    "agent": {}
  },
  "meta": {
    "correlationId": "req_01J..."
  }
}
```

`agent` contém o DTO completo. Se o onboarding ainda não criou a configuração:

```json
{
  "ok": true,
  "data": {"agent": null},
  "meta": {"correlationId": "req_01J..."}
}
```

Nesse estado, o Flutter mostra o formulário vazio. Ele não cria valores comerciais fictícios.

## 2. `v1-agent-update`

Request:

```json
{
  "workspaceId": "ws_01J...",
  "config": {
    "name": "Clara",
    "objective": "Qualificar leads e conduzir os contatos prontos para proposta.",
    "persona": "Consultora comercial experiente, clara e respeitosa.",
    "tone": "consultive",
    "mode": "assist",
    "productOffer": "CormeX Enterprise para equipes comerciais.",
    "initialMessage": "Olá! Posso entender o que sua equipe precisa?",
    "isActive": true,
    "rules": ["Nunca inventar preço, prazo ou desconto."],
    "qualificationQuestions": ["Quantas pessoas fazem parte da equipe?"],
    "schedule": {
      "enabled": true,
      "timezone": "America/Sao_Paulo",
      "daysOfWeek": [1, 2, 3, 4, 5],
      "startTime": "08:00",
      "endTime": "18:00"
    },
    "policies": {
      "maxResponseCharacters": 700,
      "maxAttemptsBeforeHandoff": 3,
      "askForName": true,
      "askForPhone": true,
      "allowPricePresentation": true,
      "allowFollowUp": true,
      "followUpDelayMinutes": 1440,
      "handoffOnRequest": true
    },
    "expectedVersion": 4
  }
}
```

Response:

```json
{
  "ok": true,
  "data": {
    "agent": {}
  },
  "meta": {
    "correlationId": "req_01J..."
  }
}
```

O backend deve devolver o DTO completo, normalizado, com `version` incrementada e `updatedAt` do servidor.

### Validações obrigatórias

- `name`: 2 a 80 caracteres;
- `objective`: 12 a 1.000;
- `persona`: 12 a 1.500;
- `productOffer`: 3 a 1.500;
- `initialMessage`: 5 a 1.000;
- pelo menos uma regra, cada uma com 3 a 500 caracteres;
- pelo menos uma pergunta, cada uma com 3 a 300 caracteres;
- `maxResponseCharacters`: 100 a 4.000;
- `maxAttemptsBeforeHandoff`: 1 a 10;
- `followUpDelayMinutes`: 5 a 10.080 quando follow-up estiver ativo;
- horário habilitado exige ao menos um dia e horários válidos/diferentes;
- `expectedVersion` deve coincidir com a versão persistida.

Se `expectedVersion` estiver desatualizada, responder `CONFLICT` sem salvar. A resposta pode incluir `details.currentVersion`, mas nunca deve incluir segredos internos.

### Persistência e auditoria

- manter no máximo um agente principal por workspace no MVP;
- `v1-agent-update` funciona como criação controlada quando `v1-agent-get` retornou `null`;
- compilar/validar o prompt no servidor antes de aceitar `isActive: true`;
- incrementar versão somente em alteração confirmada;
- criar evento `SalesAgentConfigurationUpdated` com diff seguro;
- não registrar em log dados sensíveis do provider nem o prompt completo;
- invalidar caches de configuração após o commit.

## Estados da interface

- `loading`: carregamento do contrato atual;
- `empty`: formulário para primeira configuração, sem dados inventados;
- `success`: configuração carregada/salva;
- `error`: mensagem amigável e `correlationId`;
- `isSaving`: bloqueia envio duplo;
- `CONFLICT`: exige atualização antes de uma nova tentativa.

## Erros esperados

`UNAUTHENTICATED`, `FORBIDDEN`, `WORKSPACE_NOT_FOUND`, `VALIDATION_ERROR`, `NOT_FOUND`, `CONFLICT`, `PLAN_LIMIT_REACHED`, `RATE_LIMITED`, `AI_PROVIDER_ERROR` e `INTERNAL_ERROR`.

## Arquivos Flutter

- `lib/Src/Features/agent/presentation/pages/agent_settings_page.dart`
- `lib/Src/Features/agent/presentation/controllers/agent_settings_controller.dart`
- `lib/Src/Features/agent/data/remote_agent_repository.dart`
- `lib/Src/Shared/models/agent_models.dart`

