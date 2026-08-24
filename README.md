# Agente de Vendas SaaS — Flutter

Marco inicial do front-end descrito no handoff técnico. O projeto preserva o padrão já adotado nos demais sistemas: `signals` para estado, `get_it` para injeção, `go_router` para navegação, `HttpManager` com Dio para o contrato REST/Parse e armazenamento seguro para a sessão.

## O que está pronto neste marco

- Tema claro e escuro responsivo para web, Android e iOS.
- Configuração por ambiente sem segredos hardcoded.
- Cliente centralizado para Parse REST e Cloud Functions.
- Fluxo padronizado: tela → controller com Signals → repository → HttpManager/Dio.
- Envelope de sucesso e contrato de erros normalizados.
- Sessão persistida em armazenamento seguro.
- Auth guard e redirecionamento por sessão/workspace.
- Login, cadastro, recuperação de senha e onboarding do workspace.
- Shell responsivo com todas as rotas obrigatórias do MVP registradas.
- Dashboard inicial e placeholders identificados para as próximas fases.
- Modo de demonstração local para trabalhar no front antes do backend.

## Preparar as plataformas

O ambiente usado para gerar este marco não contém o SDK do Flutter. Na primeira execução, dentro desta pasta, gere somente os runners de plataforma:

```bash
flutter create . --platforms=android,ios,web --org com.agentevendas
flutter pub get
```

O `flutter_secure_storage` 11 exige Android 6.0 ou superior. Confirme `minSdk = 23` no runner Android gerado.

## Executar

```bash
flutter run -d chrome --dart-define-from-file=config/dev.json
```

No modo de demonstração, use qualquer e-mail válido e uma senha com pelo menos oito caracteres. Para integrar ao Back4App, copie `config/staging.json.example`, forneça as chaves do ambiente e altere `USE_MOCK_DATA` para `false`.

## Comandos de qualidade

```bash
flutter analyze
flutter test
flutter build web --release --dart-define-from-file=config/staging.json
```

Não versionar `config/production.json`. A Master Key e segredos de WhatsApp, IA ou pagamento nunca pertencem ao bundle Flutter.
