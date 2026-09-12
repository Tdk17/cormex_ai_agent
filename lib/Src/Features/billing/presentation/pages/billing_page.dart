import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:agente_vendas_saas/Src/Core/di/service_locator.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/billing/domain/billing_models.dart';
import 'package:agente_vendas_saas/Src/Features/billing/presentation/controllers/billing_controller.dart';
import 'package:agente_vendas_saas/Src/Shared/components/form_error_banner.dart';
import 'package:flutter/material.dart';
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

  Future<void> _subscribe(BillingPlanModel plan) async {
    final checkoutUrl = await controller.startCheckout(plan, Uri.base.toString());
    if (!mounted || checkoutUrl == null) return;
    final uri = Uri.tryParse(checkoutUrl);
    if (uri == null || uri.scheme != 'https') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o checkout de assinatura.')),
      );
      return;
    }
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_self',
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o Mercado Pago.')),
      );
    }
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar assinatura?'),
        content: const Text(
          'O acesso aos recursos pagos será interrompido conforme o status confirmado pelo provedor de pagamento.',
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Voltar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Cancelar assinatura')),
        ],
      ),
    );
    if (confirmed != true) return;
    final success = await controller.cancelSubscription();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Assinatura cancelada.' : (controller.errorMessage.value ?? 'Não foi possível cancelar.'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = controller.state.value;
    final overview = controller.overview.value;
    final catalog = controller.catalog.value;

    return RefreshIndicator(
      onRefresh: () => controller.load(force: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 40),
        children: <Widget>[
          Text('Plano e assinatura', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          const Text(
            'Gerencie o período de teste, assinatura e limites do workspace.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          if (state == ScreenState.loading && overview == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            )
          else if (state == ScreenState.error)
            Column(
              children: <Widget>[
                FormErrorBanner(
                  message: controller.errorMessage.value ?? 'Erro ao carregar assinatura.',
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
          else if (overview == null)
            const _EmptyBilling()
          else ...<Widget>[
            _EntitlementBanner(entitlement: overview.entitlement),
            const SizedBox(height: 16),
            _CurrentPlanCard(
              overview: overview,
              cancelling: controller.isCancelling.value,
              onCancel: overview.entitlement.status == 'active' ? _cancel : null,
            ),
            const SizedBox(height: 16),
            _UsageSection(usage: overview.usage),
            const SizedBox(height: 24),
            if (catalog != null && catalog.items.isNotEmpty) ...<Widget>[
              Text('Escolha seu plano', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 5),
              Text(
                'Novas contas têm ${catalog.trialDays} dias de teste. A assinatura é processada com segurança pelo Mercado Pago.',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              _PlansGrid(
                plans: catalog.items,
                currentPlanCode: overview.plan?.id,
                busyPlanCode: controller.busyPlanCode.value,
                onSubscribe: _subscribe,
              ),
            ],
            if (controller.errorMessage.value != null) ...<Widget>[
              const SizedBox(height: 14),
              FormErrorBanner(
                message: controller.errorMessage.value!,
                correlationId: controller.correlationId.value,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _EntitlementBanner extends StatelessWidget {
  const _EntitlementBanner({required this.entitlement});

  final BillingEntitlementModel entitlement;

  @override
  Widget build(BuildContext context) {
    final (icon, title, message) = switch (entitlement.status) {
      'grandfathered' => (
          Icons.verified_outlined,
          'Acesso completo preservado',
          'Este workspace possui acesso legado completo e não depende de assinatura.',
        ),
      'trial' => (
          Icons.schedule_rounded,
          'Teste gratuito ativo',
          'Restam ${entitlement.daysRemaining ?? 0} dia(s) de acesso completo antes da assinatura ser necessária.',
        ),
      'active' => (
          Icons.check_circle_outline_rounded,
          'Assinatura ativa',
          entitlement.renewsAt == null
              ? 'Seu workspace está liberado.'
              : 'Próxima renovação em ${DateFormat('dd/MM/yyyy').format(entitlement.renewsAt!.toLocal())}.',
        ),
      'past_due' => (
          Icons.warning_amber_rounded,
          'Pagamento pendente',
          'Regularize a assinatura para manter o acesso aos recursos do CormeX.',
        ),
      'canceled' || 'cancelled' => (
          Icons.cancel_outlined,
          'Assinatura cancelada',
          'Escolha um plano para reativar os recursos do workspace.',
        ),
      _ => (
          Icons.lock_outline_rounded,
          'Período de teste encerrado',
          'Escolha um plano para continuar usando os recursos do CormeX.',
        ),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: entitlement.allowed ? AppColors.primary : Theme.of(context).colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(message, style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({required this.overview, required this.cancelling, this.onCancel});

  final BillingOverviewModel overview;
  final bool cancelling;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final plan = overview.plan;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Wrap(
          spacing: 28,
          runSpacing: 18,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'PLANO ATUAL',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  plan?.name.isNotEmpty == true ? plan!.name : 'Sem plano pago',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (plan != null && plan.price > 0) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(_price(plan), style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ],
            ),
            if (onCancel != null)
              TextButton.icon(
                onPressed: cancelling ? null : onCancel,
                icon: const Icon(Icons.cancel_outlined),
                label: Text(cancelling ? 'Cancelando...' : 'Cancelar assinatura'),
              ),
          ],
        ),
      ),
    );
  }
}

class _UsageSection extends StatelessWidget {
  const _UsageSection({required this.usage});

  final BillingUsageModel usage;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
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
    );
  }
}

class _PlansGrid extends StatelessWidget {
  const _PlansGrid({
    required this.plans,
    required this.currentPlanCode,
    required this.busyPlanCode,
    required this.onSubscribe,
  });

  final List<BillingPlanModel> plans;
  final String? currentPlanCode;
  final String? busyPlanCode;
  final ValueChanged<BillingPlanModel> onSubscribe;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 4
            : constraints.maxWidth >= 760
                ? 2
                : 1;
        final width = (constraints.maxWidth - (columns - 1) * 14) / columns;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: plans.map((plan) {
            final selected = currentPlanCode == plan.id;
            final busy = busyPlanCode == plan.id;
            return SizedBox(
              width: width,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(plan.name, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(_price(plan), style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 14),
                      for (final feature in plan.features.take(7))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Icon(Icons.check_rounded, size: 18),
                              const SizedBox(width: 7),
                              Expanded(child: Text(feature)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: selected || busyPlanCode != null ? null : () => onSubscribe(plan),
                          child: Text(selected ? 'Plano atual' : busy ? 'Abrindo...' : 'Assinar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(growable: false),
        );
      },
    );
  }
}

class _UsageCard extends StatelessWidget {
  const _UsageCard({required this.title, required this.used, required this.limit, required this.icon});

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

String _price(BillingPlanModel plan) {
  final formatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: plan.currency == 'BRL' ? 'R\$' : plan.currency,
  );
  final cycle = plan.billingCycle == 'monthly'
      ? '/mês'
      : plan.billingCycle == 'yearly'
          ? '/ano'
          : '';
  return '${formatter.format(plan.price)}$cycle';
}

class _EmptyBilling extends StatelessWidget {
  const _EmptyBilling();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Text(
          'Não há informações de assinatura disponíveis para este workspace.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
