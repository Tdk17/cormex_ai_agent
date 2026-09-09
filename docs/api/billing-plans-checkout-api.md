# CormeX CRM — API de Planos, Checkout e Assinaturas

## 1. Objetivo

Este documento define o contrato de backend necessário para a nova tela `/billing` do CormeX CRM.

O frontend foi preparado para:

- exibir catálogo de planos retornado pela API;
- trabalhar com quatro planos comerciais ativos neste primeiro lançamento;
- alternar cobrança mensal e anual;
- indicar plano atual;
- iniciar contratação por PIX, cartão de crédito ou boleto;
- exibir PIX copia e cola e QR Code quando retornados pelo provedor;
- abrir checkout seguro externo para cartão;
- abrir boleto e copiar código de barras;
- consultar novamente o status do checkout;
- continuar usando `usage.current` para assinatura atual, limites e consumo.

Não há preço autoritativo no Flutter. O backend é a fonte de verdade para plano, preço, ciclo, disponibilidade de pagamento e ativação da assinatura.

---

## 2. Cloud Functions obrigatórias

### 2.1 `v1-billing-plans-list`

Retorna o catálogo comercial disponível para o workspace.

#### Request

```json
{
  "workspaceId": "ws_01J..."
}
```

#### Response

```json
{
  "ok": true,
  "data": {
    "yearlyDiscountLabel": "2 meses grátis",
    "paymentMethods": ["pix", "credit_card", "boleto"],
    "plans": [
      {
        "id": "starter",
        "code": "starter",
        "name": "Starter",
        "description": "Para começar a organizar vendas e atendimento.",
        "currency": "BRL",
        "monthlyPrice": 0,
        "yearlyPrice": 0,
        "badge": null,
        "recommended": false,
        "active": true,
        "features": [
          "CRM comercial",
          "Gestão de leads",
          "Pipeline",
          "Conversas"
        ],
        "paymentMethods": ["pix", "credit_card", "boleto"]
      },
      {
        "id": "growth",
        "code": "growth",
        "name": "Growth",
        "description": "Para equipes que querem vender com automação e IA.",
        "currency": "BRL",
        "monthlyPrice": 0,
        "yearlyPrice": 0,
        "badge": "Mais escolhido",
        "recommended": true,
        "active": true,
        "features": [
          "Tudo do Starter",
          "Agente de IA",
          "Follow-ups",
          "Integrações"
        ],
        "paymentMethods": ["pix", "credit_card", "boleto"]
      },
      {
        "id": "business",
        "code": "business",
        "name": "Business",
        "description": "Para operações comerciais com mais volume e equipe.",
        "currency": "BRL",
        "monthlyPrice": 0,
        "yearlyPrice": 0,
        "badge": null,
        "recommended": false,
        "active": true,
        "features": [
          "Tudo do Growth",
          "Mais usuários",
          "Mais automações",
          "Mais volume de IA"
        ],
        "paymentMethods": ["pix", "credit_card", "boleto"]
      },
      {
        "id": "scale",
        "code": "scale",
        "name": "Scale",
        "description": "Para empresas com operação comercial em escala.",
        "currency": "BRL",
        "monthlyPrice": 0,
        "yearlyPrice": 0,
        "badge": null,
        "recommended": false,
        "active": true,
        "features": [
          "Tudo do Business",
          "Limites ampliados",
          "Operação multiusuário",
          "Suporte prioritário"
        ],
        "paymentMethods": ["pix", "credit_card", "boleto"]
      }
    ]
  },
  "meta": {
    "correlationId": "req_01J..."
  }
}
```

> Os valores `0` acima são deliberadamente placeholders de especificação. Definir a tabela comercial antes de produção. O frontend exibirá exatamente o valor retornado pela API.

### Regras

- retornar somente planos ativos e contratáveis pelo workspace;
- por enquanto, retornar quatro planos;
- ordenar no backend pela posição comercial (`sortOrder`);
- não confiar em qualquer preço mantido no cliente;
- permitir que métodos de pagamento sejam diferentes por plano;
- `recommended` e `badge` são controlados pelo backend para merchandising sem novo deploy do Flutter.

---

### 2.2 `v1-billing-checkout-create`

Cria uma intenção de contratação no provedor de pagamento.

#### Request

```json
{
  "workspaceId": "ws_01J...",
  "planId": "growth",
  "billingCycle": "monthly",
  "paymentMethod": "pix"
}
```

Valores aceitos:

- `billingCycle`: `monthly` | `yearly`;
- `paymentMethod`: `pix` | `credit_card` | `boleto`.

O Flutter **não envia `amount`**. O backend deve obter preço pela combinação `planId + billingCycle`.

#### Response PIX

```json
{
  "ok": true,
  "data": {
    "id": "chk_01J...",
    "status": "pending",
    "planId": "growth",
    "billingCycle": "monthly",
    "paymentMethod": "pix",
    "pixCopyPaste": "00020126...",
    "pixQrCodeBase64": "data:image/png;base64,iVBORw0KGgo...",
    "expiresAt": "2026-09-09T21:00:00.000Z"
  },
  "meta": {
    "correlationId": "req_01J..."
  }
}
```

#### Response cartão

```json
{
  "ok": true,
  "data": {
    "id": "chk_01J...",
    "status": "pending",
    "planId": "growth",
    "billingCycle": "monthly",
    "paymentMethod": "credit_card",
    "checkoutUrl": "https://checkout.provedor.com/...",
    "expiresAt": "2026-09-09T21:00:00.000Z"
  },
  "meta": {
    "correlationId": "req_01J..."
  }
}
```

#### Response boleto

```json
{
  "ok": true,
  "data": {
    "id": "chk_01J...",
    "status": "pending",
    "planId": "growth",
    "billingCycle": "yearly",
    "paymentMethod": "boleto",
    "boletoUrl": "https://checkout.provedor.com/boleto/...",
    "boletoBarcode": "34191.79001 01043.510047 ...",
    "expiresAt": "2026-09-12T23:59:59.000Z"
  },
  "meta": {
    "correlationId": "req_01J..."
  }
}
```

### Regras de criação

1. autenticar a sessão Parse;
2. validar membership do usuário no `workspaceId`;
3. permitir contratação apenas a `owner`/`admin`;
4. buscar o plano no banco;
5. validar plano ativo;
6. buscar o preço pelo ciclo escolhido;
7. validar se o método é permitido;
8. gerar uma `idempotencyKey` ou aceitar uma chave idempotente interna;
9. criar `BillingCheckoutSession` em `creating`;
10. criar pagamento/checkout no provedor;
11. salvar somente identificadores e metadados permitidos;
12. responder ao Flutter;
13. nunca ativar assinatura apenas porque o checkout foi criado.

---

### 2.3 `v1-billing-checkout-status`

Consulta o estado persistido do checkout e, quando necessário, reconcilia com o provedor.

#### Request

```json
{
  "workspaceId": "ws_01J...",
  "checkoutId": "chk_01J..."
}
```

#### Response

Deve usar o mesmo formato de `BillingCheckoutModel` retornado por `v1-billing-checkout-create`.

Estados mínimos:

- `creating`;
- `pending`;
- `waiting_payment`;
- `paid`;
- `failed`;
- `expired`;
- `cancelled`;
- `refunded`.

Quando estiver `paid`, `usage.current` já deve refletir a assinatura ativa ou a mudança de plano.

---

## 3. Endpoint existente preservado

### `usage.current`

Continua sendo utilizado pela tela para:

- plano atual;
- status da assinatura;
- ciclo atual;
- renovação;
- limites;
- consumo;
- warnings.

Não remover nem alterar campos já documentados em `docs/api/usage-api.md`.

O campo `plan.id` deve ser compatível com `plans[].id` retornado por `v1-billing-plans-list`, para que o frontend identifique o card do plano contratado.

---

## 4. Banco de dados

Os nomes podem ser adaptados ao padrão Parse/Back4App, mas a separação lógica deve ser mantida.

### 4.1 `BillingPlan`

Campos:

- `code: String` — único e estável, ex. `growth`;
- `name: String`;
- `description: String`;
- `currency: String` — inicialmente `BRL`;
- `active: Boolean`;
- `recommended: Boolean`;
- `badge: String?`;
- `sortOrder: Number`;
- `features: Array<String>`;
- `paymentMethods: Array<String>`;
- `limits: Object`;
- `createdAt`;
- `updatedAt`.

Índices:

- unique `code`;
- `active + sortOrder`.

### 4.2 `BillingPrice`

Campos:

- `plan: Pointer<BillingPlan>`;
- `billingCycle: String` (`monthly`/`yearly`);
- `amount: Number`;
- `currency: String`;
- `active: Boolean`;
- `providerPriceId: String?`;
- `validFrom: Date?`;
- `validUntil: Date?`.

Índice único lógico:

- `plan + billingCycle + active`.

Nunca sobrescrever preço histórico usado por uma cobrança concluída. Para alteração de tabela, versionar/preparar novo registro.

### 4.3 `BillingSubscription`

Campos:

- `workspace: Pointer<Workspace>`;
- `plan: Pointer<BillingPlan>`;
- `price: Pointer<BillingPrice>`;
- `status: String`;
- `billingCycle: String`;
- `provider: String`;
- `providerCustomerId: String?`;
- `providerSubscriptionId: String?`;
- `currentPeriodStart: Date`;
- `currentPeriodEnd: Date`;
- `cancelAtPeriodEnd: Boolean`;
- `cancelledAt: Date?`;
- `createdAt`;
- `updatedAt`.

Regra: apenas uma assinatura principal ativa por workspace.

### 4.4 `BillingCheckoutSession`

Campos:

- `checkoutId: String` — UUID/ULID público;
- `workspace: Pointer<Workspace>`;
- `requestedBy: Pointer<_User>`;
- `plan: Pointer<BillingPlan>`;
- `price: Pointer<BillingPrice>`;
- `billingCycle: String`;
- `paymentMethod: String`;
- `amountSnapshot: Number`;
- `currencySnapshot: String`;
- `status: String`;
- `provider: String`;
- `providerCheckoutId: String?`;
- `providerPaymentId: String?`;
- `checkoutUrl: String?`;
- `pixCopyPaste: String?`;
- `pixQrCodeBase64: String?`;
- `boletoUrl: String?`;
- `boletoBarcode: String?`;
- `expiresAt: Date?`;
- `idempotencyKey: String`;
- `paidAt: Date?`;
- `failedAt: Date?`;
- `correlationId: String`.

Índices:

- unique `checkoutId`;
- unique `idempotencyKey`;
- `workspace + status`;
- `providerPaymentId`.

### 4.5 `BillingTransaction`

Campos:

- `workspace`;
- `subscription`;
- `checkoutSession`;
- `providerPaymentId`;
- `type` — `charge`, `refund`, `chargeback`;
- `status`;
- `amount`;
- `currency`;
- `paymentMethod`;
- `paidAt`;
- `providerFee` opcional;
- `rawReference` opcional sem dados sensíveis.

### 4.6 `BillingWebhookEvent`

Campos:

- `provider`;
- `providerEventId`;
- `eventType`;
- `receivedAt`;
- `processedAt`;
- `status`;
- `attempts`;
- `payloadHash`;
- `correlationId`;
- `lastError`.

Índice único obrigatório:

- `provider + providerEventId`.

Serve para idempotência, auditoria e reprocessamento seguro.

---

## 5. Webhook do provedor

Criar endpoint HTTP público específico para o provedor, por exemplo:

```text
POST /billing/webhooks/{provider}
```

Responsabilidades:

1. validar assinatura/autenticidade do webhook;
2. obter `providerEventId`;
3. recusar/reconhecer duplicatas de forma idempotente;
4. localizar pagamento/checkout;
5. consultar o provedor quando o evento não contiver dados suficientes;
6. atualizar `BillingCheckoutSession`;
7. registrar `BillingTransaction`;
8. ativar/atualizar `BillingSubscription` somente após confirmação financeira válida;
9. atualizar período e limites de uso;
10. registrar auditoria;
11. retornar 2xx rapidamente após persistência segura.

Eventos mínimos a tratar conceitualmente:

- pagamento pendente;
- pagamento aprovado;
- pagamento recusado/cancelado;
- pagamento expirado;
- reembolso;
- chargeback;
- renovação aprovada;
- renovação falhou;
- assinatura cancelada.

Os nomes reais variam por provedor.

---

## 6. Cartão de crédito e PCI

O CormeX não deve receber ou persistir:

- número completo do cartão;
- CVV;
- senha;
- dados brutos de autenticação 3DS.

Preferência de implementação para a primeira versão:

- backend cria sessão de checkout no provedor;
- API retorna `checkoutUrl`;
- Flutter abre o checkout externo por `url_launcher`;
- provedor processa cartão e autenticação;
- webhook confirma o pagamento.

Isso reduz drasticamente a superfície PCI e o risco operacional.

---

## 7. PIX

Para PIX, o backend pode retornar:

- `pixCopyPaste`;
- `pixQrCodeBase64`;
- `expiresAt`.

O Flutter já está preparado para:

- renderizar PNG base64;
- exibir código copia e cola;
- copiar o código;
- consultar novamente o status.

Não considerar PIX pago pela mera geração do QR Code.

---

## 8. Boleto

Para boleto, retornar quando disponíveis:

- `boletoUrl`;
- `boletoBarcode`;
- `expiresAt`.

O Flutter abre a URL externamente e permite copiar o código.

A assinatura deve ser ativada somente após compensação/confirmacão do provedor.

---

## 9. Regras de segurança e autorização

Obrigatórias:

- sessão Parse válida;
- workspace sempre resolvido no servidor;
- `owner`/`admin` para iniciar contratação;
- seller/member não altera cobrança;
- nunca aceitar preço, desconto, moeda ou limite enviados pelo Flutter como autoridade;
- validar plano e preço no banco;
- validação de métodos de pagamento no backend;
- HTTPS;
- secrets do provedor apenas no backend;
- não enviar access token/secret ao Flutter;
- webhook com validação de assinatura;
- idempotência em checkout, webhook e ativação;
- logs com `correlationId`;
- não logar dados bancários/cartão;
- rate limit nos endpoints de checkout/status;
- auditoria de mudanças de plano.

---

## 10. Migração de plano

Para primeira entrega, o fluxo pode ser tratado como nova contratação/troca confirmada pelo pagamento.

Antes de liberar downgrade/upgrade automático, definir explicitamente:

- pró-rata;
- créditos;
- mudança imediata ou no próximo ciclo;
- tratamento de limites após downgrade;
- cancelamento do plano anterior no provedor;
- recuperação de falha entre provedor e banco.

Downgrade nunca deve apagar dados históricos.

---

## 11. Erros padronizados

Formato:

```json
{
  "ok": false,
  "error": {
    "code": "BILLING_PLAN_NOT_AVAILABLE",
    "message": "Este plano não está disponível para contratação.",
    "correlationId": "req_01J...",
    "details": {}
  }
}
```

Códigos mínimos:

- `UNAUTHENTICATED`;
- `FORBIDDEN`;
- `WORKSPACE_NOT_FOUND`;
- `BILLING_PLAN_NOT_FOUND`;
- `BILLING_PLAN_NOT_AVAILABLE`;
- `BILLING_PRICE_NOT_FOUND`;
- `BILLING_PAYMENT_METHOD_NOT_ALLOWED`;
- `BILLING_CHECKOUT_NOT_FOUND`;
- `BILLING_CHECKOUT_EXPIRED`;
- `BILLING_PROVIDER_ERROR`;
- `BILLING_PAYMENT_FAILED`;
- `CONFLICT`;
- `RATE_LIMITED`;
- `INTERNAL_ERROR`.

---

## 12. Arquivos frontend já preparados

- `lib/Src/Core/http/endpoints.dart`
  - `v1-billing-plans-list`;
  - `v1-billing-checkout-create`;
  - `v1-billing-checkout-status`.
- `lib/Src/Features/billing/domain/billing_models.dart`
  - ciclos;
  - métodos de pagamento;
  - catálogo;
  - planos;
  - checkout.
- `lib/Src/Features/billing/domain/billing_repository.dart`
  - contratos dos três endpoints.
- `lib/Src/Features/billing/data/remote_billing_repository.dart`
  - chamadas Parse Cloud Code reais.
- `lib/Src/Features/billing/presentation/controllers/billing_controller.dart`
  - carga de catálogo + uso atual;
  - seleção mensal/anual;
  - criação e atualização do checkout.
- `lib/Src/Features/billing/presentation/pages/billing_page.dart`
  - cards responsivos;
  - destaque comercial;
  - mensal/anual;
  - PIX/cartão/boleto;
  - checkout;
  - QR Code base64;
  - copia e cola;
  - boleto;
  - status;
  - assinatura/uso atual.

---

## 13. Ordem recomendada de implementação no backend

### P0 — necessária para a tela funcionar

1. criar classes/tabelas `BillingPlan` e `BillingPrice`;
2. cadastrar exatamente quatro planos e preços reais;
3. implementar `v1-billing-plans-list`;
4. criar `BillingCheckoutSession`;
5. implementar adapter do provedor de pagamento;
6. implementar `v1-billing-checkout-create`;
7. implementar webhook validado e idempotente;
8. criar/atualizar `BillingSubscription` após pagamento;
9. implementar `v1-billing-checkout-status`;
10. garantir compatibilidade de `usage.current` com o `plan.id` do catálogo.

### P1 — produção robusta

1. reconciliação periódica com provedor;
2. `BillingTransaction`;
3. histórico de faturas;
4. retries controlados;
5. métricas e alertas de falha;
6. fluxo de renovação/past_due;
7. cancelamento e alteração de plano.

### P2 — expansão

1. cupom/desconto;
2. trial;
3. add-ons;
4. upgrade/downgrade com pró-rata;
5. portal financeiro;
6. segunda forma de pagamento/provedor de contingência.

---

## 14. Critérios de aceite

- [ ] a API retorna quatro planos ativos em ordem definida;
- [ ] mensal/anual têm preços próprios no banco;
- [ ] o Flutter não determina o preço cobrado;
- [ ] PIX retorna código utilizável e, quando disponível, QR Code base64;
- [ ] cartão usa checkout/tokenização do provedor, sem PAN/CVV no CormeX;
- [ ] boleto retorna URL/código quando suportado;
- [ ] checkout duplicado não gera cobranças duplicadas;
- [ ] webhook duplicado não ativa assinatura duas vezes;
- [ ] pagamento pendente não ativa plano;
- [ ] pagamento aprovado ativa/muda a assinatura uma única vez;
- [ ] `usage.current.plan.id` corresponde ao catálogo;
- [ ] limites são atualizados de acordo com o plano efetivamente ativo;
- [ ] somente owner/admin contrata;
- [ ] secrets ficam no backend;
- [ ] logs possuem `correlationId` sem dados sensíveis;
- [ ] falha do provedor gera erro tratável, sem estado financeiro inconsistente;
- [ ] downgrade não apaga dados históricos.
