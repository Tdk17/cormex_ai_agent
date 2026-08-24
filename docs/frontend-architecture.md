# Arquitetura do front-end

## Padrão obrigatório do projeto

```text
Tela / Widget
  ↓
Controller com Signals
  ↓
Repository (contrato de domínio)
  ↓
Data repository / mapper
  ↓
HttpManager.restRequest (Dio)
  ↓
Parse REST / Cloud Function
```

- `signals` é o único mecanismo de estado do app.
- `get_it` centraliza dependências em `service_locator.dart` pelo alias `sl`.
- `go_router` concentra rotas e guards de autenticação/workspace.
- `HttpManager` concentra headers Parse, token de sessão, timeouts e normalização.
- `Endpoints` é a fonte versionada dos caminhos REST e nomes de Cloud Functions.
- UI não chama Dio, Parse ou classes de banco diretamente.
- Domain não conhece Back4App.
- Core não depende de feature específica, com exceção do composition root e do router, que conectam as features.

## Organização

```text
lib/
  main.dart
  Src/
    App/
      app.dart
      theme/
    Core/
      api/
      auth/
      config/
      di/
      http/
      router/
      storage/
      utils/
      widgets/
    Features/
      auth/{data,domain,presentation}
      onboarding/{data,domain,presentation}
      dashboard/{data,domain,presentation}
      leads/{data,domain,presentation}
      pipeline/{data,domain,presentation}
      conversations/{data,domain,presentation}
      agent/{data,domain,presentation}
      knowledge/{data,domain,presentation}
      followups/{data,domain,presentation}
      team/{data,domain,presentation}
      integrations/{data,domain,presentation}
      billing/{data,domain,presentation}
      settings/{data,domain,presentation}
    Shared/
      components/
      models/
```

## Estado de tela

Telas de consulta expõem `ScreenState.initial`, `loading`, `success`, `empty` e `error`. Controllers de mutação bloqueiam envio duplo pelo signal `isLoading`. O erro amigável é separado do `correlationId`, preservado apenas para diagnóstico.

## Segurança

- A Master Key nunca entra no Flutter.
- Segredos de IA, canal ou pagamento nunca entram no Flutter.
- `workspaceId` enviado pelo cliente não é autorização; o backend valida membership.
- O token de sessão fica em armazenamento seguro e é enviado em `X-Parse-Session-Token`.
- Credenciais externas serão exibidas somente mascaradas.
- Exclusões e ações destrutivas terão confirmação explícita.

## Ambientes

- `config/dev.json`: desenvolvimento com dados simulados.
- `config/staging.json`: integração ponta a ponta com credenciais de staging.
- `config/production.json`: gerado pelo pipeline e nunca versionado.

O carregamento é feito com `--dart-define-from-file`, inclusive nas configurações do VS Code.
