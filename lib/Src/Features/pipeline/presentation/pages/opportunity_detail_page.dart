import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:agente_vendas_saas/Src/Core/di/service_locator.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/pipeline/domain/pipeline_constants.dart';
import 'package:agente_vendas_saas/Src/Features/pipeline/presentation/controllers/opportunity_detail_controller.dart';
import 'package:agente_vendas_saas/Src/Features/pipeline/presentation/controllers/pipeline_controller.dart';
import 'package:agente_vendas_saas/Src/Shared/components/form_error_banner.dart';
import 'package:agente_vendas_saas/Src/Shared/models/pipeline_models.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:signals/signals_flutter.dart';

class OpportunityDetailPage extends SignalStatefulWidget {
  const OpportunityDetailPage({super.key, required this.opportunityId});

  final String opportunityId;

  @override
  State<OpportunityDetailPage> createState() => _OpportunityDetailPageState();
}

class _OpportunityDetailPageState extends State<OpportunityDetailPage> {
  late final OpportunityDetailController controller;

  @override
  void initState() {
    super.initState();
    controller = sl<OpportunityDetailController>();
    controller.load(widget.opportunityId);
  }

  @override
  Widget build(BuildContext context) {
    final opportunity = controller.opportunity.value;
    final state = controller.state.value;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 40),
      children: <Widget>[
        _DetailHeader(
          opportunity: opportunity,
          onBack: () => context.go('/pipeline'),
          onEdit: opportunity == null
              ? null
              : () => context.go('/pipeline/${opportunity.id}/edit'),
        ),
        const SizedBox(height: 20),
        if (state == ScreenState.loading && opportunity == null)
          const Card(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 58),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (state == ScreenState.error)
          _DetailError(
            message: controller.errorMessage.value ??
                'Não foi possível carregar a oportunidade.',
            correlationId: controller.correlationId.value,
            onRetry: () => controller.load(widget.opportunityId),
          )
        else if (opportunity != null) ...<Widget>[
          if (state == ScreenState.loading)
            const LinearProgressIndicator(minHeight: 2),
          _OpportunitySummary(opportunity: opportunity),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final commercial = _CommercialCard(opportunity: opportunity);
              final forecast = _ForecastCard(opportunity: opportunity);
              if (constraints.maxWidth < 820) {
                return Column(
                  children: <Widget>[
                    commercial,
                    const SizedBox(height: 16),
                    forecast,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(flex: 6, child: commercial),
                  const SizedBox(width: 16),
                  Expanded(flex: 4, child: forecast),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _TimelineCard(opportunity: opportunity),
        ],
      ],
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.opportunity,
    required this.onBack,
    required this.onEdit,
  });

  final OpportunityModel? opportunity;
  final VoidCallback onBack;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final title = Row(
          children: <Widget>[
            IconButton.filledTonal(
              tooltip: 'Voltar para o pipeline',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Detalhes da oportunidade',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Informações comerciais e previsão da negociação',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        );
        final edit = FilledButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Editar oportunidade'),
        );
        if (constraints.maxWidth < 680) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              title,
              if (opportunity != null) ...<Widget>[
                const SizedBox(height: 14),
                edit,
              ],
            ],
          );
        }
        return Row(
          children: <Widget>[
            Expanded(child: title),
            if (opportunity != null) ...<Widget>[
              const SizedBox(width: 14),
              edit,
            ],
          ],
        );
      },
    );
  }
}

class _OpportunitySummary extends StatelessWidget {
  const _OpportunitySummary({required this.opportunity});

  final OpportunityModel opportunity;

  @override
  Widget build(BuildContext context) {
    final stage = sl<PipelineController>().stages.value.where(
          (PipelineStageModel item) => item.id == opportunity.stageId,
        );
    final stageName = stage.isEmpty ? opportunity.stageId : stage.first.name;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final detailsWidth = constraints.maxWidth < 520
                ? constraints.maxWidth
                : 330.0;
            return Wrap(
              spacing: 24,
              runSpacing: 18,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                CircleAvatar(
                  radius: 31,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  foregroundColor: AppColors.primary,
                  child: Text(
                    _initials(opportunity.contactName),
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                  ),
                ),
                SizedBox(
                  width: detailsWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        opportunity.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${opportunity.companyName} • ${opportunity.contactName}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                _Pill(
                  label: stageName,
                  icon: Icons.view_kanban_outlined,
                  color: AppColors.blue,
                ),
                _Pill(
                  label: _outcomeLabel(opportunity.outcome),
                  icon: opportunity.outcome == OpportunityOutcomes.won
                      ? Icons.emoji_events_outlined
                      : opportunity.outcome == OpportunityOutcomes.lost
                          ? Icons.trending_down_rounded
                          : Icons.pending_actions_outlined,
                  color: opportunity.outcome == OpportunityOutcomes.won
                      ? AppColors.accent
                      : opportunity.outcome == OpportunityOutcomes.lost
                          ? AppColors.danger
                          : AppColors.warning,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CommercialCard extends StatelessWidget {
  const _CommercialCard({required this.opportunity});

  final OpportunityModel opportunity;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Dados comerciais', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 18),
            _InfoRow(
              icon: Icons.business_outlined,
              label: 'Empresa',
              value: opportunity.companyName,
            ),
            _InfoRow(
              icon: Icons.badge_outlined,
              label: 'Contato',
              value: opportunity.contactName,
            ),
            _InfoRow(
              icon: Icons.inventory_2_outlined,
              label: 'Produto ou serviço',
              value: opportunity.product ?? 'Não informado',
            ),
            _InfoRow(
              icon: Icons.person_outline_rounded,
              label: 'Responsável',
              value: opportunity.ownerName ?? 'Sem responsável',
            ),
            _InfoRow(
              icon: Icons.ads_click_outlined,
              label: 'Origem',
              value: _sourceLabel(opportunity.source),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: opportunity.leadId.isEmpty
                  ? null
                  : () => context.go('/leads/${opportunity.leadId}'),
              icon: const Icon(Icons.person_search_outlined),
              label: const Text('Abrir lead vinculado'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForecastCard extends StatelessWidget {
  const _ForecastCard({required this.opportunity});

  final OpportunityModel opportunity;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Previsão', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 18),
            Text(
              NumberFormat.currency(locale: 'pt_BR', symbol: r'R$')
                  .format(opportunity.value),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                const Icon(Icons.percent_rounded, color: AppColors.blue),
                const SizedBox(width: 8),
                const Expanded(child: Text('Probabilidade de fechamento')),
                Text(
                  '${opportunity.probability}%',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: opportunity.probability.clamp(0, 100) / 100,
              minHeight: 8,
              borderRadius: BorderRadius.circular(20),
            ),
            const SizedBox(height: 22),
            _InfoRow(
              icon: Icons.schedule_rounded,
              label: 'Sem interação',
              value: '${opportunity.daysWithoutInteraction} dia(s)',
            ),
            _InfoRow(
              icon: Icons.event_outlined,
              label: 'Próxima atividade',
              value: _date(opportunity.nextActivityAt),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.opportunity});

  final OpportunityModel opportunity;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Linha do tempo', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 18),
            _TimelineItem(
              icon: Icons.update_rounded,
              title: 'Última atualização',
              date: opportunity.updatedAt,
            ),
            _TimelineItem(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Última interação',
              date: opportunity.lastInteractionAt,
            ),
            _TimelineItem(
              icon: Icons.add_circle_outline_rounded,
              title: 'Oportunidade criada',
              date: opportunity.createdAt,
              last: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.icon,
    required this.title,
    required this.date,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final DateTime? date;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              if (!last)
                Expanded(
                  child: Container(width: 1, color: AppColors.border),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(
                    _date(date),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({
    required this.message,
    required this.correlationId,
    required this.onRetry,
  });

  final String message;
  final String? correlationId;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        FormErrorBanner(message: message, correlationId: correlationId),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Tentar novamente'),
        ),
      ],
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String _outcomeLabel(String value) {
  return switch (value) {
    OpportunityOutcomes.won => 'Ganho',
    OpportunityOutcomes.lost => 'Perdido',
    _ => 'Em aberto',
  };
}

String _sourceLabel(String value) {
  return switch (value) {
    'website' => 'Site',
    'whatsapp' => 'WhatsApp',
    'instagram' => 'Instagram',
    'referral' => 'Indicação',
    'campaign' => 'Campanha',
    'import' => 'Importação',
    _ => 'Manual',
  };
}

String _date(DateTime? value) {
  if (value == null) return 'Não informado';
  return DateFormat("dd/MM/yyyy 'às' HH:mm").format(value.toLocal());
}
