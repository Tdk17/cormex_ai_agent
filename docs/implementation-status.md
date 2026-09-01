# Estado da implementação

## Marco 1 — Fundação

- [x] Estrutura `lib/Src` com Core, Features e Shared.
- [x] Tema SaaS responsivo.
- [x] `get_it`, `go_router` e `signals` padronizados.
- [x] `HttpManager.restRequest`, `HttpMethod` e `Endpoints`.
- [x] Configuração por ambiente.
- [x] Sessão local segura.
- [x] Login, cadastro e recuperação de senha.
- [x] Guard de autenticação e workspace.
- [x] Onboarding de empresa e objetivo do agente.
- [x] Shell responsivo e rotas de todos os módulos do MVP.
- [x] Dashboard visual com estados de tela e repositório remoto.
- [x] Dashboard sem valores fixos: métricas, variações e conversas vêm da API.
- [x] Sessão em modo fail-closed: qualquer falha de validação retorna ao Login.
- [x] DTOs mínimos previstos no handoff.

## Marco 2 — Leads

- [x] Leads: lista, detalhe, criação, edição, filtros, paginação e importação.
- [x] Contrato completo da API de Leads para integração com Cloud Code/Back4App.
- [x] Parser CSV com cabeçalhos em português/inglês, validação por linha e pré-visualização.
- [x] Repositório remoto conectado diretamente ao Cloud Code.
- [x] Testes unitários do parser CSV.

## Marco 3 — Pipeline

- [x] Kanban responsivo com cinco etapas, cards comerciais e resumo do funil.
- [x] Busca, filtro por responsável e visualização mobile expansível.
- [x] Movimento otimista de oportunidades com rollback em falha da API.
- [x] Criação, edição e detalhe de oportunidade vinculada a um lead.
- [x] Repositório remoto para `v1-pipeline-list`, `v1-pipeline-get`, `v1-pipeline-create`, `v1-pipeline-update` e `v1-pipeline-move`.
- [x] Contratos de API separados para cada tela do módulo.
- [x] Login com restauração da empresa vinculada e onboarding idempotente para criar a empresa uma única vez.

## Marco 4 — Conversas

- [x] Caixa de entrada responsiva com busca, filtros e paginação por cursor.
- [x] Thread paginada com mensagens de cliente, humano, IA e sistema.
- [x] Composer real com limite, trava de envio simultâneo e idempotência.
- [x] Rascunho preservado durante atualização e apagado somente após sucesso.
- [x] Assumir, transferir, devolver para a IA e alternar entre `auto`, `assist` e `human`.
- [x] Contexto do lead com qualificação, tags, produto, carrinho, histórico e notas.
- [x] Repositório conectado às cinco Cloud Functions de conversas, sem mocks.
- [x] Contratos de API separados para caixa de entrada e atendimento.

## Marco 5 — Agente de IA

- [x] Configuração de nome, objetivo, persona, tom, produto/oferta e abertura.
- [x] Regras obrigatórias e perguntas de qualificação editáveis.
- [x] Modos `auto`, `assist` e `human`, com ativação independente.
- [x] Horários, dias ativos e fuso do workspace.
- [x] Guardrails de resposta, tentativas, coleta de contato, preço, follow-up e handoff.
- [x] Salvamento remoto com versão esperada e tratamento de conflito concorrente.
- [x] Console sandbox com lead, contexto, histórico e resposta estruturada.
- [x] Diagnóstico com produto, regras usadas, ação sugerida, warnings e handoff.
- [x] Repositório remoto para `v1-agent-get`, `v1-agent-update` e `v1-agent-test-reply`, sem mocks.
- [x] Contratos de API separados para configuração e console.

## Marco 6 — Central de Aquisição

- [x] Nova landing autenticada em `/acquisition`; Dashboard permanece no menu.
- [x] Visão gerencial com contas Google/Meta, métricas, filtros e paginação.
- [x] Lista responsiva de campanhas com visualizar, editar, pausar, retomar, duplicar e encerrar.
- [x] Wizard em nove etapas: produto, objetivo, canais, público, orçamento, criativo, destino, automação e revisão.
- [x] Rascunho remoto idempotente, bloqueio de envio duplicado e conflito por versão.
- [x] Publicação somente após validação completa e autorização explícita.
- [x] Criativo assistido por IA, sempre editável e sem publicação automática.
- [x] Detalhe com desempenho, configuração, automação e IDs dos provedores.
- [x] Repository remoto conectado aos seis contratos `v1-acquisition-*`, sem mocks.
- [x] Contrato de API em `docs/api/acquisition-api.md`.

## Próximas fases do handoff

- [x] Conversas: inbox, thread, composer, rascunho e modos auto/assist/human.
- [x] Agente de IA: configuração e console de teste.
- [x] Central de Aquisição: visão, wizard, detalhe, rascunho e publicação.
- [ ] Base de Conhecimento.
- [ ] Integração de canal.
- [ ] Follow-ups e tarefas.
- [x] Dashboard conectado ao contrato de métricas remotas.
- [ ] Plano, uso, equipe e permissões.
- [ ] Hardening, testes ponta a ponta e staging.

As rotas das fases futuras permanecem visíveis como placeholders para validar navegação e responsividade, mas não são consideradas funcionalidades concluídas. Conversas, Agente de IA e Central de Aquisição já foram substituídos por implementações remotas completas.
