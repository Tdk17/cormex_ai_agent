import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:agente_vendas_saas/Src/Core/di/service_locator.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/billing/domain/billing_models.dart';
import 'package:agente_vendas_saas/Src/Features/billing/presentation/controllers/billing_controller.dart';
import 'package:agente_vendas_saas/Src/Shared/components/form_error_banner.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signals/signals_flutter.dart';

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
    final overview = controller.overview.value;

    return RefreshIndicator(
      onRefresh: () => controller.load(force: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 40),
        children: <Widget>[
          Text('Plano e uso', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          const Text(
            'Acompanhe assinatura, limites e consumo do workspace.',
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
                  message: controller.errorMessage.value ??
                      'Erro ao carregar plano e uso.',
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
          else
            _BillingContent(overview: overview),
        ],
      ),
    );
  }
}

class _BillingContent extends StatelessWidget {
  const _BillingContent({required this.overview});

  final BillingOverviewModel overview;

  @override
  Widget build(BuildContext context) {
    final plan = overview.plan;
    final usage = overview.usage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Card(
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
                      plan?.name.isNotEmpty == true ? plan!.name : 'Plano não informado',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (plan != null) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        _price(plan),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
                if (plan?.renewsAt != null)
                  _InfoChip(
                    icon: Icons.event_repeat_outlined,
                    label:
                        'Renovação ${DateFormat('dd/MM/yyyy').format(plan!.renewsAt!.toLocal())}',
                  ),
              ],
            ),
          ),
        ),
        if (overview.warnings.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
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
        ],
        const SizedBox(height: 16),
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
        if (plan != null && plan.features.isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Recursos do plano', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  for (final feature in plan.features)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.check_circle_outline, size: 19),
                          const SizedBox(width: 9),
                          Expanded(child: Text(feature)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  static String _price(BillingPlanModel plan) {
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(avatar: Icon(icon, size: 18), label: Text(label));
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
          'Não há informações de plano disponíveis para este workspace.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
