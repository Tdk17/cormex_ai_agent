import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:agente_vendas_saas/Src/Core/di/service_locator.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/leads/domain/lead_labels.dart';
import 'package:agente_vendas_saas/Src/Features/leads/presentation/controllers/lead_detail_controller.dart';
import 'package:agente_vendas_saas/Src/Features/leads/presentation/controllers/leads_controller.dart';
import 'package:agente_vendas_saas/Src/Features/leads/presentation/widgets/lead_status_badge.dart';
import 'package:agente_vendas_saas/Src/Shared/components/form_error_banner.dart';
import 'package:agente_vendas_saas/Src/Shared/models/lead_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:signals/signals_flutter.dart';

class LeadDetailPage extends SignalStatefulWidget {
  const LeadDetailPage({super.key, required this.leadId});

  final String leadId;

  @override
  State<LeadDetailPage> createState() => _LeadDetailPageState();
}

class _LeadDetailPageState extends State<LeadDetailPage> {
  late final LeadDetailController controller;

  @override
  void initState() {
    super.initState();
    controller = sl<LeadDetailController>();
    controller.load(
      widget.leadId,
      cached: sl<LeadsController>().findById(widget.leadId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lead = controller.lead.value;
    final state = controller.state.value;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 40),
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton.filledTonal(
              tooltip: 'Voltar para leads',
              onPressed: () => context.go('/leads'),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Detalhes do lead', style: Theme.of(context).textTheme.headlineMedium),
            ),
            if (lead != null)
              FilledButton.icon(
                onPressed: () => context.go('/leads/${lead.id}/edit'),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar'),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (state == ScreenState.loading && lead == null)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(54),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (state == ScreenState.error)
          Column(
            children: <Widget>[
              FormErrorBanner(
                message: controller.errorMessage.value ?? 'Erro ao carregar lead.',
                correlationId: controller.correlationId.value,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => controller.load(widget.leadId),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
              ),
            ],
          )
        else if (lead != null) ...<Widget>[
          if (state == ScreenState.loading) const LinearProgressIndicator(minHeight: 2),
          _LeadSummary(lead: lead),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final contact = _ContactCard(lead: lead);
              final qualification = _QualificationCard(lead: lead);
              if (constraints.maxWidth < 820) {
                return Column(
                  children: <Widget>[
                    contact,
                    const SizedBox(height: 16),
                    qualification,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(flex: 6, child: contact),
                  const SizedBox(width: 16),
                  Expanded(flex: 4, child: qualification),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _ActivityPlaceholder(lead: lead),
        ],
      ],
    );
  }
}

class _LeadSummary extends StatelessWidget {
  const _LeadSummary({required this.lead});

  final LeadModel lead;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Wrap(
          spacing: 20,
          runSpacing: 18,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              foregroundColor: AppColors.primary,
              child: Text(
                lead.name.trim().isEmpty ? '?' : lead.name.trim()[0].toUpperCase(),
                style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
              ),
            ),
            SizedBox(
              width: 290,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(lead.name, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 3),
                  Text(
                    lead.company ?? 'Empresa não informada',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            LeadStatusBadge(status: lead.status),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.bolt_rounded, color: AppColors.warning, size: 19),
                  const SizedBox(width: 5),
                  Text(
                    'Score ${lead.score}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.lead});

  final LeadModel lead;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Contato', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 18),
            _InfoRow(icon: Icons.mail_outline_rounded, label: 'E-mail', value: lead.email ?? 'Não informado'),
            _InfoRow(icon: Icons.phone_outlined, label: 'Telefone', value: lead.phone ?? 'Não informado'),
            _InfoRow(icon: Icons.business_outlined, label: 'Empresa', value: lead.company ?? 'Não informada'),
            _InfoRow(icon: Icons.ads_click_outlined, label: 'Origem', value: LeadLabels.source(lead.source)),
          ],
        ),
      ),
    );
  }
}

class _QualificationCard extends StatelessWidget {
  const _QualificationCard({required this.lead});

  final LeadModel lead;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Qualificação', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 18),
            _LabelValue(label: 'Status', child: LeadStatusBadge(status: lead.status)),
            _LabelValue(
              label: 'Último contato',
              child: Text(
                lead.lastContactAt == null
                    ? 'Ainda não realizado'
                    : DateFormat("dd/MM/yyyy 'às' HH:mm").format(lead.lastContactAt!),
              ),
            ),
            _LabelValue(
              label: 'Tags',
              child: lead.tags.isEmpty
                  ? const Text('Nenhuma tag')
                  : Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: lead.tags
                          .map((String tag) => Chip(label: Text(tag), visualDensity: VisualDensity.compact))
                          .toList(growable: false),
                    ),
            ),
            _LabelValue(
              label: 'Criado em',
              child: Text(DateFormat("dd/MM/yyyy 'às' HH:mm").format(lead.createdAt)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityPlaceholder extends StatelessWidget {
  const _ActivityPlaceholder({required this.lead});

  final LeadModel lead;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Linha do tempo', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _TimelineItem(
              icon: Icons.person_add_alt_1_outlined,
              title: 'Lead adicionado à base',
              subtitle: DateFormat("dd/MM/yyyy 'às' HH:mm").format(lead.createdAt),
            ),
            _TimelineItem(
              icon: Icons.update_rounded,
              title: 'Dados atualizados',
              subtitle: DateFormat("dd/MM/yyyy 'às' HH:mm").format(lead.updatedAt),
              last: true,
            ),
          ],
        ),
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
      padding: const EdgeInsets.only(bottom: 17),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
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

class _LabelValue extends StatelessWidget {
  const _LabelValue({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Column(
          children: <Widget>[
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              foregroundColor: AppColors.primary,
              child: Icon(icon, size: 18),
            ),
            if (!last) Container(width: 1, height: 28, color: AppColors.border),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
