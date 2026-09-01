# CormeX Flutter 0.6.0+8 — Central de Aquisição

## Mudanças desta versão

- `/acquisition` passou a ser a landing autenticada e o primeiro item do menu.
- O onboarding concluído e o guard de sessão agora direcionam para a Central.
- `/dashboard` foi preservado como visão analítica.
- A classe `Endpoints` foi alinhada aos contratos `v1-*` já concluídos.
- `pipelineCreate` foi corrigido para `v1-pipeline-create`.
- Os nomes sem prefixo de Conhecimento, Follow-ups, Tarefas, Integrações e Uso foram preservados.
- Seis contratos `v1-acquisition-*` foram acrescentados ao final de `Endpoints`.
- A Central ganhou contas Google/Meta, métricas, filtros, paginação, lista responsiva e ações de campanha.
- O wizard possui nove etapas e salva rascunho pela API com idempotência.
- A publicação exige validação completa, versão esperada e autorização explícita.
- A IA sugere criativo editável, sem publicar ou alterar orçamento automaticamente.
- O detalhe da campanha mostra desempenho, configuração, automação e rastreamento.
- O gasto de mídia foi separado visual e contratualmente da assinatura CormeX.
- Foi criado o contrato `docs/api/acquisition-api.md` e teste de models/payload.

## Novas rotas

- `/acquisition`
- `/acquisition/new`
- `/acquisition/:campaignId`
- `/acquisition/:campaignId/edit`

## Novas Cloud Functions

- `v1-acquisition-overview`
- `v1-acquisition-campaign-get`
- `v1-acquisition-campaign-upsert`
- `v1-acquisition-campaign-publish`
- `v1-acquisition-campaign-action`
- `v1-acquisition-ai-suggest`

## Validação necessária no ambiente Flutter

```bash
flutter pub get
flutter analyze
flutter test
flutter build web --release --dart-define-from-file=config/staging.json
```

Este ambiente de geração não contém o SDK Flutter/Dart. Foram executadas verificações estruturais de imports, delimitadores, endpoints, JSON e links de documentação; os comandos acima permanecem obrigatórios antes do merge.
