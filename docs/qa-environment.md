# Ambiente QA — CormeX CRM

## Objetivo

Separar testes funcionais e regressão da versão de produção sem substituir o site principal.

## URLs

- Produção: https://tdk17.github.io/cormex_ai_agent/
- QA: https://tdk17.github.io/cormex_ai_agent/qa/

## Branches

- `main`: produção
- `qa`: homologação/QA

Mudanças devem ser testadas primeiro em `qa`. Depois de aprovadas, podem ser promovidas para `main`.

## Backend

O build QA usa:

- `APP_ENV=staging`
- `PARSE_SERVER_URL=https://parseapi.back4app.com`

Credenciais preferenciais:

- `QA_PARSE_APPLICATION_ID`
- `QA_PARSE_REST_API_KEY`

Se esses secrets ainda não existirem, o workflow usa temporariamente os secrets de produção. Nesse modo, o QA deve usar exclusivamente um workspace de teste para não misturar dados.

### Recomendado

Criar um segundo app Back4App para homologação e preencher os dois secrets QA acima. Isso isola banco, Cloud Code, webhooks e integrações.

## Conta de teste

Criar uma conta dedicada, por exemplo:

- Nome: CormeX QA
- Papel: admin
- Workspace: Genesys QA
- Dados: somente dados fictícios/controlados

A conta QA pode acessar os módulos necessários para regressão, mas não deve receber Master Key, tokens privados, segredos de provedor ou dados reais de clientes.

## Fluxo de deploy

### Push em `qa`

O workflow `.github/workflows/deploy-qa-pages.yml`:

1. valida o branch QA com `flutter analyze` e `flutter test`;
2. compila QA com `APP_ENV=staging` e base `/qa/`;
3. compila novamente a `main` para a raiz de produção;
4. publica os dois no mesmo GitHub Pages sem substituir a raiz por código QA.

### Push em `main`

O workflow de produção:

1. valida e compila produção;
2. compila o branch `qa` no subdiretório `/qa/`;
3. publica o artefato combinado.

## Checklist mínimo de regressão

1. Login / logout / recuperação de senha.
2. Seleção e criação de workspace.
3. Dashboard e métricas.
4. Leads: listar, criar, editar e importar.
5. Pipeline: criar/mover oportunidades.
6. Conversas: iniciar contato, enviar e receber mensagens.
7. Agente comercial: carregar, salvar, ativar e testar resposta.
8. IA Operacional: ativar, salvar, consultar atividade e monitor.
9. Follow-ups.
10. Campanhas e Google Ads.
11. WhatsApp / integrações.
12. Conhecimento.
13. Equipe e permissões.
14. Billing.
15. Responsividade mobile/desktop.
16. Erros de autorização e isolamento entre workspaces.

## Promoção para produção

Uma alteração só deve ir para `main` depois de:

- build QA aprovado;
- testes automatizados aprovados;
- fluxo funcional testado na URL QA;
- nenhum erro crítico novo nos logs;
- contratos de API compatíveis com o Cloud Code implantado.

## Segurança

Nunca versionar Application ID, REST API Key, Master Key, access tokens, client secrets ou webhooks secrets. Credenciais de ambiente devem ficar em GitHub Secrets e/ou variáveis protegidas do backend.
