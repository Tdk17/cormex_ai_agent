import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:agente_vendas_saas/Src/Core/di/service_locator.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:agente_vendas_saas/Src/Features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:agente_vendas_saas/Src/Shared/components/form_error_banner.dart';
import 'package:agente_vendas_saas/Src/Shared/models/dashboard_metrics_model.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

class DashboardPage extends SignalStatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardController controller;

  @override
  void initState() {
    super.initState();
    controller = sl<DashboardController>();
    if (controller.state.value == ScreenState.initial) controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final state = controller.state.value;
    final metrics = controller.metrics.value;
    final workspace = sl<AuthController>().session.value?.selectedWorkspace;

    return RefreshIndicator(
      onRefresh: () => controller.load(force: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 40),
        children: <Widget>[
          _DashboardHeader(
            workspaceName: workspace?.name ?? 'Seu workspace',
            selectedPeriod: controller.period.value,
            onPeriodChanged: controller.changePeriod,
          ),
          const SizedBox(height: 24),
          if (state == ScreenState.loading && metrics == null)
            const _DashboardSkeleton()
          else if (state == ScreenState.error)
            Column(
              children: <Widget>[
                FormErrorBanner(
                  message: controller.errorMessage.value ?? 'Erro ao carregar dashboard.',
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
          else if (state == ScreenState.empty || metrics == null)
            const _EmptyDashboard()
          else
            _DashboardContent(metrics: metrics, refreshing: state == ScreenState.loading),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.workspaceName,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  final String workspaceName;
  final String selectedPeriod;
  final ValueChanged<String> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18,
      runSpacing: 16,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Visão geral', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 5),
            Text(
              'Acompanhe o desempenho comercial de $workspaceName.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        SegmentedButton<String>(
          segments: const <ButtonSegment<String>>[
            ButtonSegment<String>(value: '7d', label: Text('7 dias')),
            ButtonSegment<String>(value: '30d', label: Text('30 dias')),
            ButtonSegment<String>(value: '90d', label: Text('90 dias')),
          ],
          selected: <String>{selectedPeriod},
          onSelectionChanged: (Set<String> values) => onPeriodChanged(values.first),
          showSelectedIcon: false,
        ),
      ],
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.metrics, required this.refreshing});

  final DashboardMetricsModel metrics;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    final cards = <_KpiData>[
      _KpiData(
        label: 'Leads no período',
        value: _formatInt(metrics.totalLeads),
        change: '+12,4%',
        icon: Icons.groups_2_outlined,
        color: AppColors.blue,
      ),
      _KpiData(
        label: 'Conversas ativas',
        value: _formatInt(metrics.activeConversations),
        change: '+8,1%',
        icon: Icons.forum_outlined,
        color: AppColors.primary,
      ),
      _KpiData(
        label: 'Leads qualificados',
        value: _formatInt(metrics.qualifiedLeads),
        change: '+15,7%',
        icon: Icons.verified_outlined,
        color: AppColors.accent,
      ),
      _KpiData(
        label: 'Taxa de conversão',
        value: '${metrics.conversionRate.toStringAsFixed(1).replaceAll('.', ',')}%',
        change: '+2,3 p.p.',
        icon: Icons.trending_up_rounded,
        color: AppColors.warning,
      ),
    ];

    return Column(
      children: <Widget>[
        if (refreshing) const LinearProgressIndicator(minHeight: 2),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final columns = constraints.maxWidth >= 1180
                ? 4
                : constraints.maxWidth >= 650
                    ? 2
                    : 1;
            final width = (constraints.maxWidth - ((columns - 1) * 14)) / columns;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: cards
                  .map((data) => SizedBox(width: width, child: _KpiCard(data: data)))
                  .toList(growable: false),
            );
          },
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (constraints.maxWidth < 900) {
              return Column(
                children: <Widget>[
                  _FunnelCard(metrics: metrics),
                  const SizedBox(height: 16),
                  const _RecentConversationsCard(),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 6, child: _FunnelCard(metrics: metrics)),
                const SizedBox(width: 16),
                const Expanded(flex: 4, child: _RecentConversationsCard()),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        const _SetupAlert(),
      ],
    );
  }

  static String _formatInt(int value) {
    final text = value.toString();
    return text.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
  }
}

class _KpiData {
  const _KpiData({
    required this.label,
    required this.value,
    required this.change,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String change;
  final IconData icon;
  final Color color;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.data});

  final _KpiData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(19),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: data.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(data.icon, color: data.color, size: 21),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    data.change,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(data.value, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 3),
            Text(data.label, style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _FunnelCard extends StatelessWidget {
  const _FunnelCard({required this.metrics});

  final DashboardMetricsModel metrics;

  @override
  Widget build(BuildContext context) {
    final maxValue = metrics.funnel.values.fold<int>(1, (int a, int b) => a > b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Funil comercial', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            const Text(
              'Distribuição dos leads por etapa',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ...metrics.funnel.entries.map((entry) {
              final progress = entry.value / maxValue;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(child: Text(entry.key)),
                        Text(
                          entry.value.toString(),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 9,
                        backgroundColor: AppColors.border.withValues(alpha: 0.6),
                        color: Color.lerp(AppColors.accent, AppColors.primary, 1 - progress),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _RecentConversationsCard extends StatelessWidget {
  const _RecentConversationsCard();

  @override
  Widget build(BuildContext context) {
    const items = <(String, String, String, int)>[
      ('Marina Souza', 'Quero entender os planos...', '2 min', 2),
      ('Rafael Lima', 'Podemos marcar uma demonstração?', '9 min', 1),
      ('Camila Martins', 'Obrigado pelo atendimento!', '24 min', 0),
      ('Bruno Rocha', 'Qual o prazo de implantação?', '38 min', 3),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Conversas recentes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton(onPressed: () {}, child: const Text('Ver inbox')),
              ],
            ),
            const SizedBox(height: 10),
            ...items.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  foregroundColor: AppColors.primary,
                  child: Text(item.$1.substring(0, 1)),
                ),
                title: Text(item.$1, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(item.$2, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      item.$3,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                    if (item.$4 > 0)
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          item.$4.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupAlert extends StatelessWidget {
  const _SetupAlert();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: <Widget>[
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.campaign_outlined, color: AppColors.warning),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Conecte seu primeiro canal',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Ative WhatsApp, e-mail ou chat web para começar a receber conversas reais.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(onPressed: null, child: Text('Configurar integrações')),
          ],
        ),
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: List<Widget>.generate(
        4,
        (int index) => Container(
          width: 245,
          height: 150,
          decoration: BoxDecoration(
            color: AppColors.border.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 54),
        child: Column(
          children: <Widget>[
            const Icon(Icons.insights_outlined, size: 50, color: AppColors.primary),
            const SizedBox(height: 16),
            Text('Seu dashboard começa aqui', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Cadastre ou importe seus primeiros leads para visualizar os indicadores.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
