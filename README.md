# Agente de Vendas SaaS — Flutter

Marcos 1 a 6 do front-end descrito no handoff técnico. O projeto preserva o padrão já adotado nos demais sistemas: `signals` para estado, `get_it` para injeção, `go_router` para navegação, `HttpManager` com Dio para o contrato REST/Parse e armazenamento seguro para a sessão.

## O que está pronto neste marco

- Tema claro e escuro responsivo para web, Android e iOS.
- Configuração por ambiente sem segredos hardcoded.
- Cliente centralizado para Parse REST e Cloud Functions.
- Fluxo padronizado: tela → controller com Signals → repository → HttpManager/Dio.
- Envelope de sucesso e contrato de erros normalizados.
- Sessão persistida em armazenamento seguro.
- Sessão validada no servidor em todo início; sessão antiga ou não confirmada é apagada.
- Auth guard e redirecionamento por sessão/workspace.
- Login, cadastro, recuperação de senha e onboarding idempotente da empresa.
- Shell responsivo com todas as rotas obrigatórias do MVP registradas.
- Central de Aquisição como nova tela principal; Dashboard mantido como visão analítica.
- Módulo de Leads responsivo com busca, filtros, paginação por cursor, cadastro, edição e detalhes.
- Importação CSV com normalização, validação por linha, pré-visualização e resumo.
- Repositórios conectados diretamente às APIs e contrato detalhado em `docs/leads-api.md`.
- Modelo de planilha em `docs/leads-import-template.csv`.
- Pipeline responsivo com resumo, busca, filtro por responsável e Kanban de cinco etapas.
- Criação, edição e detalhe de oportunidades vinculadas aos leads.
- Movimento otimista no Kanban, persistência pela API e rollback automático em falha.
- Documentação por tela em `docs/api/pipeline-board-api.md`, `docs/api/opportunity-form-api.md` e `docs/api/opportunity-detail-api.md`.
- Dashboard sem dados fixos, alimentado integralmente por `v1-dashboard-metrics`.
- Conversas em layout responsivo de até três painéis, com inbox, filtros, paginação e thread.
- Atendimento conectado diretamente às APIs de envio, atribuição e modos da IA, sem mock.
- Contratos por tela em `docs/api/conversations-inbox-api.md` e `docs/api/conversation-thread-api.md`.
- Configuração completa do Agente de IA com versionamento, horários, modos e guardrails.
- Console sandbox conectado a `v1-agent-test-reply`, sem envio externo e com diagnóstico estruturado.
- Contratos por tela em `docs/api/agent-settings-api.md` e `docs/api/agent-test-console-api.md`.
- Central de Aquisição com visão gerencial, contas Google/Meta, filtros, paginação e ações de campanha.
- Wizard responsivo em nove etapas, rascunho remoto, revisão, publicação autorizada e assistência da IA.
- Detalhe da campanha com desempenho, configuração, automação, rastreamento e separação financeira explícita.
- Contrato completo em `docs/api/acquisition-api.md`.
- Resumo de todas as mudanças em `docs/release-0.6.0.md`.

## Documentação do backend

Para implementar todas as APIs no Back4App, comece pelo
[`docs/backend-api-implementation-guide.md`](docs/backend-api-implementation-guide.md).
Ele contém o catálogo completo, prioridade, segurança multi-tenant,
idempotência, classes mínimas, critérios de aceite e links para os contratos
detalhados de cada tela, além dos webhooks e workers da automação.

O envelope comum e o índice resumido permanecem em
[`docs/api-contract.md`](docs/api-contract.md).

## Preparar as plataformas

O ambiente usado para gerar este marco não contém o SDK do Flutter. Na primeira execução, dentro desta pasta, gere somente os runners de plataforma:

```bash
flutter create . --platforms=android,ios,web --org com.agentevendas
flutter pub get
```

O `flutter_secure_storage` 11 exige Android 6.0 ou superior. Confirme `minSdk = 23` no runner Android gerado. Para o seletor de CSV do `file_picker` 12, defina o deployment target do runner iOS como 14.0 ou superior.

## Executar

```bash
flutter run -d chrome --dart-define-from-file=config/dev.json
```

Preencha `PARSE_APPLICATION_ID` e, se a aplicação exigir, `PARSE_REST_API_KEY` no arquivo do ambiente. O front utiliza diretamente o Parse Server/Back4App e não possui repositórios de dados simulados.

## Comandos de qualidade

```bash
flutter analyze
flutter test
flutter build web --release --dart-define-from-file=config/staging.json
```

Não versionar `config/production.json`. A Master Key e segredos de WhatsApp, IA ou pagamento nunca pertencem ao bundle Flutter.
