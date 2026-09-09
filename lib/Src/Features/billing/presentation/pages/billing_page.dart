import 'dart:convert';
import 'dart:typed_data';

import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:agente_vendas_saas/Src/Core/di/service_locator.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/billing/domain/billing_models.dart';
import 'package:agente_vendas_saas/Src/Features/billing/presentation/controllers/billing_controller.dart';
import 'package:agente_vendas_saas/Src/Shared/components/form_error_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:signals/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class BillingPage extends SignalStatefulWidget {
  const BillingPage({super.key});

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  late final BillingController controller;

  @override
  void initState() {
    super.initState();
    controller = sl<BillingController>();
    if (controller.state.value == ScreenState.initial) controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final state = controller.state.value;
    final catalog = controller.catalog.value;
    final overview = controller.overview.value;
    final cycle = controller.billingCycle.value;

    return RefreshIndicator(
      onRefresh: () => controller.load(force: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 40),
        children: <Widget>[
          _Header(
            cycle: cycle,
            yearlyDiscountLabel: catalog?.yearlyDiscountLabel,
            onCycleChanged: controller.selectCycle,
          ),
          const SizedBox(height: 24),
          if (state == ScreenState.loading && catalog == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(56),
                child: CircularProgressIndicator(),
              ),
            )
          else if (state == ScreenState.error)
            Column(
              children: <Widget>[
                FormErrorBanner(
                  message: controller.errorMessage.value ??
                      'Erro ao carregar os planos.',
                  correlationId: controller.correlationId.value,
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => controller.load(force: true),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tentar novamente'),
                ),
              ],
            )
          else if (catalog == null || catalog.plans.isEmpty)
            const _EmptyBilling()
          else ...<Widget>[
            _PlanGrid(
              plans: catalog.plans.where((plan) => plan.active).toList(growable: false),
              currentPlan: overview?.plan,
              cycle: cycle,
              defaultPaymentMethods: catalog.paymentMethods,
              onSelectPlan: _openCheckout,
            ),
            const SizedBox(height: 24),
            _PaymentTrustStrip(paymentMethods: catalog.paymentMethods),
            if (overview != null) ...<Widget>[
              const SizedBox(height: 28),
              _CurrentSubscriptionSection(overview: overview),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _openCheckout(BillingCatalogPlanModel plan) async {
    final catalog = controller.catalog.value;
    final methods = plan.paymentMethods.isNotEmpty
        ? plan.paymentMethods
        : (catalog?.paymentMethods ?? const <BillingPaymentMethod>[]);
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => _CheckoutSheet(
        controller: controller,
        plan: plan,
        paymentMethods: methods,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.cycle,
    required this.onCycleChanged,
    this.yearlyDiscountLabel,
  });

  final BillingCycle cycle;
  final String? yearlyDiscountLabel;
  final ValueChanged<BillingCycle> onCycleChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 20,
      runSpacing: 18,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: <Widget>[
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'CORMEX CRM',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Planos para transformar operação comercial em escala',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Escolha o plano, defina a cobrança mensal ou anual e conclua o pagamento por PIX, cartão ou boleto conforme disponibilidade.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
            ],
          ),
        ),
        _CycleSelector(
          cycle: cycle,
          yearlyDiscountLabel: yearlyDiscountLabel,
          onChanged: onCycleChanged,
        ),
      ],
    );
  }
}

class _CycleSelector extends StatelessWidget {
  const _CycleSelector({
    required this.cycle,
    required this.onChanged,
    this.yearlyDiscountLabel,
  });

  final BillingCycle cycle;
  final ValueChanged<BillingCycle> onChanged;
  final String? yearlyDiscountLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _CycleButton(
            label: 'Mensal',
            selected: cycle == BillingCycle.monthly,
            onTap: () => onChanged(BillingCycle.monthly),
          ),
          _CycleButton(
            label: yearlyDiscountLabel == null || yearlyDiscountLabel!.isEmpty
                ? 'Anual'
                : 'Anual • $yearlyDiscountLabel',
            selected: cycle == BillingCycle.yearly,
            onTap: () => onChanged(BillingCycle.yearly),
          ),
        ],
      ),
    );
  }
}

class _CycleButton extends StatelessWidget {
  const _CycleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _PlanGrid extends StatelessWidget {
  const _PlanGrid({
    required this.plans,
    required this.currentPlan,
    required this.cycle,
    required this.defaultPaymentMethods,
    required this.onSelectPlan,
  });

  final List<BillingCatalogPlanModel> plans;
  final BillingPlanModel? currentPlan;
  final BillingCycle cycle;
  final List<BillingPaymentMethod> defaultPaymentMethods;
  final ValueChanged<BillingCatalogPlanModel> onSelectPlan;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final columns = constraints.maxWidth >= 1320
            ? 4
            : constraints.maxWidth >= 900
                ? 2
                : 1;
        final spacing = 14.0;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: <Widget>[
            for (final plan in plans)
              SizedBox(
                width: width,
                child: _PlanCard(
                  plan: plan,
                  cycle: cycle,
                  current: currentPlan?.id == plan.id ||
                      (plan.code.isNotEmpty && currentPlan?.id == plan.code),
                  paymentMethods: plan.paymentMethods.isNotEmpty
                      ? plan.paymentMethods
                      : defaultPaymentMethods,
                  onSelect: () => onSelectPlan(plan),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.cycle,
    required this.current,
    required this.paymentMethods,
    required this.onSelect,
  });

  final BillingCatalogPlanModel plan;
  final BillingCycle cycle;
  final bool current;
  final List<BillingPaymentMethod> paymentMethods;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: plan.currency == 'BRL' ? 'R\$' : plan.currency,
    );
    final price = plan.priceFor(cycle);
    final monthlyEquivalent = plan.monthlyEquivalentFor(cycle);
    final highlighted = plan.recommended;

    return Container(
      constraints: const BoxConstraints(minHeight: 520),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: highlighted ? AppColors.primary : AppColors.border,
          width: highlighted ? 1.6 : 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: highlighted
                ? AppColors.primary.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: highlighted ? 28 : 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        plan.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      if (plan.description.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 7),
                        Text(
                          plan.description,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (current)
                  const _Badge(label: 'Plano atual')
                else if ((plan.badge ?? '').isNotEmpty)
                  _Badge(label: plan.badge!),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              cycle == BillingCycle.yearly
                  ? formatter.format(monthlyEquivalent)
                  : formatter.format(price),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
            ),
            Text(
              cycle == BillingCycle.yearly
                  ? '/mês equivalente • ${formatter.format(price)} faturado/ano'
                  : '/mês',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: current ? null : onSelect,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor:
                      highlighted ? AppColors.primary : AppColors.ink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: Text(current ? 'Plano contratado' : 'Escolher ${plan.name}'),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 18),
            const Text(
              'Incluído no plano',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            const SizedBox(height: 12),
            for (final feature in plan.features)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(height: 1.35, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            const Spacer(),
            if (paymentMethods.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                paymentMethods.map((method) => method.label).join(' • '),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PaymentTrustStrip extends StatelessWidget {
  const _PaymentTrustStrip({required this.paymentMethods});

  final List<BillingPaymentMethod> paymentMethods;

  @override
  Widget build(BuildContext context) {
    final methods = paymentMethods.isEmpty
        ? BillingPaymentMethod.values
        : paymentMethods;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.lock_outline_rounded, size: 19, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Pagamento processado com segurança',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          for (final method in methods)
            Chip(
              avatar: Icon(_paymentIcon(method), size: 17),
              label: Text(method.label),
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.border),
            ),
        ],
      ),
    );
  }
}

class _CheckoutSheet extends StatefulWidget {
  const _CheckoutSheet({
    required this.controller,
    required this.plan,
    required this.paymentMethods,
  });

  final BillingController controller;
  final BillingCatalogPlanModel plan;
  final List<BillingPaymentMethod> paymentMethods;

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<_CheckoutSheet> {
  late BillingPaymentMethod selectedMethod;

  @override
  void initState() {
    super.initState();
    selectedMethod = widget.paymentMethods.isNotEmpty
        ? widget.paymentMethods.first
        : BillingPaymentMethod.pix;
    widget.controller.clearCheckout();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final cycle = controller.billingCycle.value;
    final checkout = controller.checkout.value;
    final loading = controller.checkoutLoading.value;
    final error = controller.errorMessage.value;
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: widget.plan.currency == 'BRL' ? 'R\$' : widget.plan.currency,
    );

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              18,
              24,
              24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Contratar ${widget.plan.name}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${formatter.format(widget.plan.priceFor(cycle))} • ${cycle == BillingCycle.monthly ? 'mensal' : 'anual'}',
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (checkout == null) ...<Widget>[
                  const Text(
                    'Como você quer pagar?',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      for (final method in widget.paymentMethods.isEmpty
                          ? BillingPaymentMethod.values
                          : widget.paymentMethods)
                        ChoiceChip(
                          selected: selectedMethod == method,
                          avatar: Icon(_paymentIcon(method), size: 17),
                          label: Text(method.label),
                          onSelected: (_) => setState(() => selectedMethod = method),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _PaymentMethodNotice(method: selectedMethod),
                  if (error != null) ...<Widget>[
                    const SizedBox(height: 14),
                    FormErrorBanner(
                      message: error,
                      correlationId: controller.correlationId.value,
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: loading ? null : _createCheckout,
                    icon: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.lock_rounded),
                    label: Text(loading ? 'Preparando pagamento...' : 'Continuar para pagamento'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'O preço final é validado no servidor. Dados sensíveis do cartão não passam pelo CormeX.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ] else
                  _CheckoutResult(
                    checkout: checkout,
                    loading: loading,
                    onRefresh: controller.refreshCheckout,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createCheckout() async {
    final result = await widget.controller.createCheckout(
      plan: widget.plan,
      paymentMethod: selectedMethod,
    );
    if (!mounted || result == null) return;

    if (selectedMethod == BillingPaymentMethod.creditCard &&
        (result.checkoutUrl ?? '').isNotEmpty) {
      await _openExternal(result.checkoutUrl!);
    }
  }
}

class _PaymentMethodNotice extends StatelessWidget {
  const _PaymentMethodNotice({required this.method});

  final BillingPaymentMethod method;

  @override
  Widget build(BuildContext context) {
    final text = switch (method) {
      BillingPaymentMethod.pix =>
        'O PIX pode retornar QR Code e código copia e cola. A assinatura é ativada após confirmação do provedor.',
      BillingPaymentMethod.creditCard =>
        'Você será direcionado ao checkout seguro do provedor para informar os dados do cartão.',
      BillingPaymentMethod.boleto =>
        'O boleto será gerado pelo provedor. A ativação ocorre depois da compensação do pagamento.',
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.textSecondary, height: 1.45),
      ),
    );
  }
}

class _CheckoutResult extends StatelessWidget {
  const _CheckoutResult({
    required this.checkout,
    required this.loading,
    required this.onRefresh,
  });

  final BillingCheckoutModel checkout;
  final bool loading;
  final Future<BillingCheckoutModel?> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final pixImage = _decodeBase64(checkout.pixQrCodeBase64);
    final paid = checkout.status == 'paid' || checkout.status == 'active';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: (paid ? AppColors.accent : AppColors.warning)
                .withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                paid ? Icons.check_circle_rounded : Icons.schedule_rounded,
                color: paid ? AppColors.accent : AppColors.warning,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  paid
                      ? 'Pagamento confirmado. Sua assinatura está ativa.'
                      : 'Pagamento criado. Status: ${checkout.status}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        if (pixImage != null) ...<Widget>[
          const SizedBox(height: 18),
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.memory(pixImage, width: 220, height: 220),
            ),
          ),
        ],
        if ((checkout.pixCopyPaste ?? '').isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          _CopyField(
            label: 'PIX copia e cola',
            value: checkout.pixCopyPaste!,
          ),
        ],
        if ((checkout.boletoBarcode ?? '').isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          _CopyField(
            label: 'Código do boleto',
            value: checkout.boletoBarcode!,
          ),
        ],
        if ((checkout.checkoutUrl ?? '').isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => _openExternal(checkout.checkoutUrl!),
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Abrir checkout seguro'),
          ),
        ],
        if ((checkout.boletoUrl ?? '').isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _openExternal(checkout.boletoUrl!),
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('Abrir boleto'),
          ),
        ],
        if (!paid) ...<Widget>[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: loading ? null : onRefresh,
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            label: const Text('Verificar pagamento'),
          ),
        ],
      ],
    );
  }
}

class _CopyField extends StatelessWidget {
  const _CopyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                SelectableText(value, maxLines: 3),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copiar',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Código copiado.')),
                );
              }
            },
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
    );
  }
}

class _CurrentSubscriptionSection extends StatelessWidget {
  const _CurrentSubscriptionSection({required this.overview});

  final BillingOverviewModel overview;

  @override
  Widget build(BuildContext context) {
    final plan = overview.plan;
    final usage = overview.usage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Sua assinatura e consumo',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            if (plan?.renewsAt != null)
              Chip(
                avatar: const Icon(Icons.event_repeat_outlined, size: 18),
                label: Text(
                  'Renovação ${DateFormat('dd/MM/yyyy').format(plan!.renewsAt!.toLocal())}',
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (overview.warnings.isNotEmpty)
          for (final warning in overview.warnings)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.warning_amber_rounded),
                  title: Text(warning.message),
                  subtitle: warning.metric.isEmpty ? null : Text(warning.metric),
                ),
              ),
            ),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final width = constraints.maxWidth >= 900
                ? (constraints.maxWidth - 28) / 3
                : constraints.maxWidth;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: <Widget>[
                SizedBox(
                  width: width,
                  child: _UsageCard(
                    title: 'Mensagens de IA',
                    used: usage.aiMessagesUsed,
                    limit: usage.aiMessagesLimit,
                    icon: Icons.auto_awesome_outlined,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _UsageCard(
                    title: 'Leads',
                    used: usage.leadsUsed,
                    limit: usage.leadsLimit,
                    icon: Icons.groups_2_outlined,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _UsageCard(
                    title: 'Membros',
                    used: usage.membersUsed,
                    limit: usage.membersLimit,
                    icon: Icons.group_outlined,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _UsageCard extends StatelessWidget {
  const _UsageCard({
    required this.title,
    required this.used,
    required this.limit,
    required this.icon,
  });

  final String title;
  final int used;
  final int limit;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final progress = limit <= 0 ? 0.0 : (used / limit).clamp(0.0, 1.0).toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 7),
            Text(
              limit > 0 ? '$used de $limit' : '$used usados',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress, minHeight: 8),
          ],
        ),
      ),
    );
  }
}

class _EmptyBilling extends StatelessWidget {
  const _EmptyBilling();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Text(
          'Nenhum plano comercial foi disponibilizado pela API para este workspace.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

IconData _paymentIcon(BillingPaymentMethod method) => switch (method) {
      BillingPaymentMethod.pix => Icons.pix_rounded,
      BillingPaymentMethod.creditCard => Icons.credit_card_rounded,
      BillingPaymentMethod.boleto => Icons.receipt_long_rounded,
    };

Uint8List? _decodeBase64(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final normalized = raw.contains(',') ? raw.split(',').last : raw;
    return base64Decode(normalized);
  } on FormatException {
    return null;
  }
}

Future<void> _openExternal(String rawUrl) async {
  final uri = Uri.tryParse(rawUrl);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
