# Guia mestre de implementação das APIs — CormeX AI Agent

Versão do contrato: **2026-09-03**  
Backend alvo: **Parse Server / Back4App Cloud Code**  
Cliente: **Flutter Web, Android e iOS**

Este é o ponto de entrada para implementar todo o backend exigido pelo front atual e pelos módulos planejados. Os contratos detalhados continuam separados por tela para facilitar implementação e teste.

## 1. Fonte de verdade

1. Os nomes chamados pelo Flutter estão em `lib/Src/Core/http/endpoints.dart`.
2. Os requests e responses obrigatórios estão neste guia e nos documentos vinculados.
3. Em divergência, o payload realmente serializado pelo repositório Flutter prevalece até que front e backend sejam migrados juntos.
4. `knowledge.*`, `followups.*`, `tasks.list`, `integrations.*` e `usage.current` permanecem sem prefixo `v1`.
5. `v1-conversations-delivery-webhook` é interno ao backend e **não** deve ser adicionado à classe `Endpoints` do aplicativo.

## 2. Transporte padrão

Cloud Functions:

```http
POST {PARSE_SERVER_URL}/functions/{functionName}
Content-Type: application/json
X-Parse-Application-Id: {applicationId}
X-Parse-REST-API-Key: {restApiKey, quando configurada}
X-Parse-Session-Token: {sessionToken}
```

O Parse Server envolve o retorno da função no campo `result`. Portanto, o JSON HTTP completo é:

```json
{
  "result": {
    "ok": true,
    "data": {},
    "meta": {
      "correlationId": "req_01J...",
      "nextCursor": null
    }
  }
}
```

Dentro da Cloud Function, retorne apenas o objeto que começa em `ok`. O Parse adiciona `result`.

### Erro normalizado

```json
{
  "ok": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Dados inválidos.",
    "correlationId": "req_01J...",
    "details": {
      "field": "name",
      "reason": "required"
    }
  }
}
```

Nunca retornar stack trace, token, segredo, prompt compilado ou detalhes internos do provedor.

## 3. Middleware obrigatório para todas as funções privadas

Toda função que recebe `workspaceId` deve executar, nesta ordem:

1. gerar ou recuperar `correlationId`;
2. exigir `request.user` autenticado;
3. validar formato e presença do `workspaceId`;
4. buscar uma `Membership` ativa do usuário no workspace;
5. validar o papel exigido pela ação;
6. consultar e gravar sempre com filtro de `workspaceId` no servidor;
7. validar schema, limites e enums antes de persistir;
8. aplicar idempotência ou controle de versão quando o contrato exigir;
9. registrar auditoria sem dados sensíveis;
10. devolver o envelope normalizado.

Receber um `workspaceId` no body não concede acesso. Para IDs pertencentes a outro tenant, devolver `NOT_FOUND` ou `WORKSPACE_NOT_FOUND` sem confirmar que o recurso existe.

### Papéis

| Papel | Permissões mínimas |
| --- | --- |
| `owner` | Todas as operações; transferência/exclusão exige confirmação reforçada |
| `admin` | Configuração, integrações, agente, conhecimento, follow-ups e equipe; não altera owner |
| `seller` | Leads, Pipeline e Conversas; leitura limitada dos demais módulos |

## 4. Catálogo completo

### 4.1 Parse REST nativo

| Método e rota | Uso | Autenticação | Documento |
| --- | --- | --- | --- |
| `GET /login` | Login por e-mail e senha | Não | [Login](api/login-api.md) |
| `POST /users` | Criar usuário | Não | [Cadastro e empresa](api/register-company-api.md) |
| `POST /logout` | Invalidar sessão | Sim | [Login](api/login-api.md) |
| `POST /requestPasswordReset` | Solicitar recuperação | Não | [Login](api/login-api.md) |
| `POST /files/{fileName}` | Upload de mídia e documentos | Sim | [Uploads](api/uploads-api.md) |

### 4.2 Cloud Functions consumidas pelo Flutter atual

| Prioridade | Domínio | Função | Documento |
| --- | --- | --- | --- |
| P0 | Sessão | `v1-auth-me` | [Login](api/login-api.md) |
| P0 | Workspace | `v1-workspaces-create` | [Cadastro e empresa](api/register-company-api.md) |
| P1 | Dashboard | `v1-dashboard-metrics` | [Dashboard](api/dashboard-api.md) |
| P0 | Leads | `v1-leads-list` | [Leads](leads-api.md) |
| P0 | Leads | `v1-leads-get` | [Leads](leads-api.md) |
| P0 | Leads | `v1-leads-create` | [Leads](leads-api.md) |
| P0 | Leads | `v1-leads-update` | [Leads](leads-api.md) |
| P1 | Leads | `v1-leads-import` | [Leads](leads-api.md) |
| P0 | Pipeline | `v1-pipeline-list` | [Pipeline](api/pipeline-board-api.md) |
| P0 | Pipeline | `v1-pipeline-get` | [Detalhe](api/opportunity-detail-api.md) |
| P0 | Pipeline | `v1-pipeline-create` | [Formulário](api/opportunity-form-api.md) |
| P0 | Pipeline | `v1-pipeline-update` | [Formulário](api/opportunity-form-api.md) |
| P0 | Pipeline | `v1-pipeline-move` | [Pipeline](api/pipeline-board-api.md) |
| P0 | Conversas | `v1-conversations-list` | [Inbox](api/conversations-inbox-api.md) |
| P0 | Conversas | `v1-conversations-get` | [Thread](api/conversation-thread-api.md) |
| P0 | Conversas | `v1-conversations-send-message` | [Thread](api/conversation-thread-api.md) |
| P0 | Conversas | `v1-conversations-assign` | [Thread](api/conversation-thread-api.md) |
| P0 | Conversas | `v1-conversations-set-mode` | [Thread](api/conversation-thread-api.md) |
| P0 | Conversas | `v1-conversations-start` | [Iniciar conversa](api/conversation-start-api.md) |
| P0 | Agente | `v1-agent-get` | [Configuração](api/agent-settings-api.md) |
| P0 | Agente | `v1-agent-update` | [Configuração](api/agent-settings-api.md) |
| P1 | Agente | `v1-agent-test-reply` | [Sandbox](api/agent-test-console-api.md) |
| P1 | Conhecimento | `knowledge.list` | [Conhecimento](api/knowledge-api.md) |
| P1 | Conhecimento | `knowledge.create` | [Conhecimento](api/knowledge-api.md) |
| P1 | Conhecimento | `knowledge.delete` | [Conhecimento](api/knowledge-api.md) |
| P1 | Follow-ups | `followups.list` | [Follow-ups](api/followups-api.md) |
| P1 | Follow-ups | `followups.upsert` | [Follow-ups](api/followups-api.md) |
| P1 | Equipe | `v1-team-list` | [Equipe](api/team-api.md) |
| P1 | Equipe | `v1-team-invite` | [Equipe](api/team-api.md) |
| P1 | Equipe | `v1-team-update-role` | [Equipe](api/team-api.md) |
| P0 | Aquisição | `v1-acquisition-overview` | [Aquisição](api/acquisition-api.md) |
| P0 | Aquisição | `v1-acquisition-campaign-get` | [Aquisição](api/acquisition-api.md) |
| P0 | Aquisição | `v1-acquisition-campaign-upsert` | [Aquisição](api/acquisition-api.md) |
| P0 | Aquisição | `v1-acquisition-campaign-publish` | [Aquisição](api/acquisition-api.md) |
| P0 | Aquisição | `v1-acquisition-campaign-action` | [Aquisição](api/acquisition-api.md) |
| P0 | Aquisição | `v1-acquisition-ai-suggest` | [Aquisição](api/acquisition-api.md) |
| P0 | Google Ads | `v1-google-ads-connection-status` | [Google Ads OAuth](api/google-ads-oauth-api.md) |
| P0 | Google Ads | `v1-google-ads-oauth-start` | [Google Ads OAuth](api/google-ads-oauth-api.md) |

### 4.3 Contratos já registrados para telas futuras

Essas funções já existem nominalmente em `Endpoints`, mas as telas ainda podem estar em evolução. Implemente o contrato sem renomeá-las.

| Domínio | Função | Documento |
| --- | --- | --- |
| Tarefas | `tasks.list` | [Tarefas](api/tasks-api.md) |
| Integrações genéricas | `integrations.list` | [Integrações](api/integrations-api.md) |
| Integrações genéricas | `integrations.connect` | [Integrações](api/integrations-api.md) |
| Plano e uso | `usage.current` | [Plano e uso](api/usage-api.md) |

### 4.4 Contratos do backend que não pertencem ao Flutter

| Método/worker | Responsabilidade | Documento |
| --- | --- | --- |
| `GET /oauth/google-ads/callback` | Finalizar OAuth e guardar refresh token | [Google Ads OAuth](api/google-ads-oauth-api.md) |
| `POST /webhooks/google-ads/leads/{publicIntegrationId}` | Receber lead form do Google | [Runtime automático](api/automation-runtime-api.md) |
| `GET /webhooks/whatsapp` | Verificação do webhook Meta | [Runtime automático](api/automation-runtime-api.md) |
| `POST /webhooks/whatsapp` | Receber mensagens/status do WhatsApp | [Runtime automático](api/automation-runtime-api.md) |
| `v1-conversations-delivery-webhook` | Normalizar confirmação de entrega | [Runtime automático](api/automation-runtime-api.md) |
| `knowledge.process` | Extrair, dividir e indexar fonte | [Runtime automático](api/automation-runtime-api.md) |
| `conversations.ai-reply` | Gerar resposta autorizada da IA | [Runtime automático](api/automation-runtime-api.md) |
| `followups.dispatch` | Executar follow-ups vencidos | [Runtime automático](api/automation-runtime-api.md) |
| `acquisition.metrics-sync` | Sincronizar métricas dos provedores | [Runtime automático](api/automation-runtime-api.md) |

Os quatro últimos nomes representam workers privados ou jobs; não devem ser expostos ao aplicativo nem aceitar sessão de usuário como autorização suficiente.

### 4.5 Extensões documentadas, ainda não registradas no Flutter

| Função | Uso |
| --- | --- |
| `v1-google-ads-accounts` | Listar contas acessíveis após OAuth |
| `v1-google-ads-select-account` | Selecionar o customer que receberá campanhas |
| `v1-google-ads-disconnect` | Revogar/desconectar a integração |
| `v1-workspace-settings-get` | Carregar configurações da empresa |
| `v1-workspace-settings-update` | Salvar configurações da empresa |
| `v1-workspace-delete-request` | Iniciar exclusão reforçada |
| `v1-workspace-delete-confirm` | Confirmar exclusão com token de uso único |

Antes de o Flutter chamar essas extensões, adicionar as constantes correspondentes em `Endpoints` numa mudança versionada.

## 5. Convenções de implementação

### 5.1 Idempotência

| Operação | Chave obrigatória | Comportamento ao repetir |
| --- | --- | --- |
| Criar workspace | `idempotencyKey` | Retornar o mesmo workspace/membership |
| Iniciar conversa | `clientRequestId` | Retornar a mesma conversa |
| Enviar mensagem | `clientRequestId` | Retornar a mesma mensagem |
| Criar/editar campanha | `clientRequestId` | Retornar a mutação já confirmada |
| Publicar campanha | `clientRequestId` | Nunca publicar duas vezes |
| Criar conhecimento | `clientRequestId` | Nunca duplicar fonte/job |
| Salvar follow-up | `clientRequestId` | Nunca criar regra duplicada |
| Convidar membro | `clientRequestId` | Nunca enviar dois convites |
| Webhook Google | `lead_id` | Um único evento/lead por integração |
| Webhook WhatsApp | ID do evento/mensagem Meta | Um único evento/mensagem |

Persistir a chave com `workspaceId`, operação, hash seguro do resultado e expiração adequada. Se a mesma chave vier com payload diferente, responder `CONFLICT`.

### 5.2 Concorrência otimista

Campos `expectedVersion` devem ser comparados atomicamente. Em sucesso, incrementar `version`. Em divergência:

```json
{
  "ok": false,
  "error": {
    "code": "CONFLICT",
    "message": "O conteúdo foi alterado em outra sessão. Atualize antes de salvar.",
    "correlationId": "req_01J...",
    "details": { "currentVersion": 4 }
  }
}
```

### 5.3 Paginação

- cursor opaco; não expor `skip`, posição de banco ou chave interna;
- ordenação estável com desempate por ID;
- `limit` mínimo 1 e máximo definido por função;
- devolver `meta.nextCursor=null` quando não houver próxima página;
- filtros fazem parte do contexto do cursor; cursor usado com filtros diferentes é inválido.

### 5.4 Datas, moeda e telefone

- datas em ISO 8601 UTC;
- moeda em código ISO 4217 e valores como número decimal;
- telefone persistido preferencialmente em E.164;
- arrays vazios em vez de `null` para coleções;
- IDs e enums como strings estáveis.

## 6. Códigos de erro

| Código | Quando usar |
| --- | --- |
| `UNAUTHENTICATED` | sessão ausente, inválida ou expirada |
| `FORBIDDEN` | membership sem papel suficiente |
| `WORKSPACE_NOT_FOUND` | workspace não autorizado/ausente |
| `VALIDATION_ERROR` | campo, enum ou regra inválida |
| `NOT_FOUND` | recurso não encontrado dentro do workspace |
| `CONFLICT` | versão, estado ou chave idempotente conflitante |
| `PLAN_LIMIT_REACHED` | limite contratado atingido |
| `RATE_LIMITED` | excesso de chamadas |
| `INTEGRATION_NOT_CONNECTED` | canal necessário desconectado |
| `ADS_ACCOUNT_NOT_CONNECTED` | conta de anúncios não selecionada |
| `AUTHORIZATION_ERROR` | autorização do provedor expirada/revogada |
| `PAYMENT_ISSUE` | problema de faturamento no provedor de anúncios |
| `PUBLICATION_ERROR` | falha segura ao publicar campanha |
| `AI_NOT_CONFIGURED` | provedor/modelo de IA ausente |
| `AI_PROVIDER_ERROR` | falha do provedor de IA |
| `AI_INVALID_RESPONSE` | IA respondeu fora do schema esperado |
| `EXTERNAL_PROVIDER_ERROR` | erro de canal/serviço externo |
| `FILE_UPLOAD_ERROR` | upload não concluído |
| `INTERNAL_ERROR` | falha inesperada, sem detalhes internos |

## 7. Classes mínimas no Parse

| Classe | Finalidade |
| --- | --- |
| `_User` | identidade Parse |
| `Workspace` | empresa/tenant |
| `Membership` | vínculo, papel e status |
| `AgentConfig` | configuração versionada do agente |
| `Lead` | contato e origem de aquisição |
| `PipelineStage` | etapas do funil |
| `Opportunity` | oportunidade vinculada ao lead |
| `Conversation` | atendimento, canal, modo e responsável |
| `Message` | mensagens inbound/outbound e status |
| `KnowledgeSource` | fonte enviada pelo usuário |
| `KnowledgeChunk` | trecho indexado por workspace |
| `FollowUpRule` | regra configurável |
| `FollowUpExecution` | tentativa, resultado e deduplicação |
| `Task` | ação operacional atribuível |
| `Integration` | estado público sanitizado da integração |
| `IntegrationCredential` | segredos criptografados e inacessíveis ao cliente |
| `AdCampaign` | rascunho e estado de publicação |
| `AdProviderOperation` | tentativa externa e IDs retornados |
| `UsageCounter` | consumo por período e métrica |
| `IdempotencyRecord` | proteção contra repetição |
| `AuditEvent` | ator, ação, recurso e correlationId |

Todas as classes de negócio devem possuir `workspaceId` indexado, exceto as globais controladas pelo servidor. `IntegrationCredential`, `IdempotencyRecord` e dados brutos de webhook não podem ter leitura direta pelo cliente.

## 8. Ordem recomendada de implementação

1. middleware comum, envelopes, sessão, membership e auditoria;
2. autenticação/workspace;
3. integrações Google Ads e WhatsApp;
4. Leads, Pipeline e Conversas;
5. Agente e Base de Conhecimento;
6. runtime automático de lead, resposta, envio e status;
7. Follow-ups e Tarefas;
8. Aquisição e sincronização de métricas;
9. Dashboard;
10. Equipe, Uso e Configurações.

## 9. Critérios de aceite do backend

- [ ] todos os nomes correspondem exatamente ao catálogo;
- [ ] nenhuma função privada funciona sem sessão e membership ativa;
- [ ] nenhum recurso cruza workspaces;
- [ ] respostas seguem o envelope comum e incluem `correlationId`;
- [ ] listas usam cursor estável;
- [ ] operações repetíveis são idempotentes;
- [ ] atualizações concorrentes respondem `CONFLICT`;
- [ ] tokens e segredos nunca chegam ao Flutter ou aos logs;
- [ ] webhooks validam autenticidade, persistem antes de confirmar e deduplicam eventos;
- [ ] a IA respeita modo, horário, opt-out, limites, conhecimento e handoff;
- [ ] follow-ups param após resposta, venda, perda ou atendimento humano;
- [ ] testes cobrem happy path, validação, sessão, RBAC, tenant, idempotência e falha externa;
- [ ] fluxo de staging passa por anúncio → lead → conversa → IA → Pipeline → conversão → Dashboard.

## 10. Índice de documentos

- [Contrato geral](api-contract.md)
- [Uploads de arquivos](api/uploads-api.md)
- [Login e sessão](api/login-api.md)
- [Cadastro e empresa](api/register-company-api.md)
- [Dashboard](api/dashboard-api.md)
- [Leads](leads-api.md)
- [Pipeline](api/pipeline-board-api.md)
- [Oportunidade — formulário](api/opportunity-form-api.md)
- [Oportunidade — detalhe](api/opportunity-detail-api.md)
- [Conversas — inbox](api/conversations-inbox-api.md)
- [Conversas — thread](api/conversation-thread-api.md)
- [Conversas — início](api/conversation-start-api.md)
- [Agente — configuração](api/agent-settings-api.md)
- [Agente — sandbox](api/agent-test-console-api.md)
- [Conhecimento](api/knowledge-api.md)
- [Follow-ups](api/followups-api.md)
- [Tarefas](api/tasks-api.md)
- [Equipe](api/team-api.md)
- [Integrações](api/integrations-api.md)
- [Google Ads OAuth](api/google-ads-oauth-api.md)
- [Central de Aquisição](api/acquisition-api.md)
- [Plano e uso](api/usage-api.md)
- [Configurações](api/settings-api.md)
- [Runtime automático, webhooks e workers](api/automation-runtime-api.md)
- [Fluxo automático até a venda](api/sales-automation-flow.md)
