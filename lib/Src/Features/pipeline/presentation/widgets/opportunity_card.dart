import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:agente_vendas_saas/Src/Features/pipeline/domain/pipeline_constants.dart';
import 'package:agente_vendas_saas/Src/Shared/models/pipeline_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum OpportunityCardAction { view, edit, move }

class OpportunityCard extends StatelessWidget {
  const OpportunityCard({
    super.key,
    required this.opportunity,
    required this.onAction,
    this.moving = false,
    this.compact = false,
  });

  final OpportunityModel opportunity;
  final ValueChanged<OpportunityCardAction> onAction;
  final bool moving;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final inactiveDays = opportunity.daysWithoutInteraction;
    final inactivityColor = inactiveDays >= 7
        ? AppColors.danger
        : inactiveDays >= 3
            ? AppColors.warning
            : AppColors.textSecondary;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: moving ? 0.55 : 1,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => onAction(OpportunityCardAction.view),
          child: Padding(
            padding: EdgeInsets.all(compact ? 14 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      foregroundColor: AppColors.primary,
                      child: Text(
                        _initials(opportunity.contactName),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            opportunity.companyName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            opportunity.contactName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<OpportunityCardAction>(
                      tooltip: 'Ações da oportunidade',
                      enabled: !moving,
                      onSelected: onAction,
                      itemBuilder: (BuildContext context) => const <
                          PopupMenuEntry<OpportunityCardAction>>[
                        PopupMenuItem<OpportunityCardAction>(
                          value: OpportunityCardAction.view,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.open_in_new_rounded),
                            title: Text('Ver detalhes'),
                          ),
                        ),
                        PopupMenuItem<OpportunityCardAction>(
                          value: OpportunityCardAction.edit,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Editar'),
                          ),
                        ),
                        PopupMenuItem<OpportunityCardAction>(
                          value: OpportunityCardAction.move,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.drive_file_move_outline),
                            title: Text('Mover etapa'),
                          ),
                        ),
                      ],
                      icon: const Icon(Icons.more_horiz_rounded, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  opportunity.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        NumberFormat.currency(locale: 'pt_BR', symbol: r'R$')
                            .format(opportunity.value),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.blue.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${opportunity.probability}%',
                        style: const TextStyle(
                          color: AppColors.blue,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                const Divider(height: 1),
                const SizedBox(height: 11),
                Row(
                  children: <Widget>[
                    Icon(Icons.schedule_rounded, size: 15, color: inactivityColor),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        inactiveDays == 0
                            ? 'Interação hoje'
                            : '$inactiveDays dia${inactiveDays == 1 ? '' : 's'} sem interação',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: inactivityColor,
                          fontSize: 11,
                          fontWeight: inactiveDays >= 7
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (opportunity.outcome != OpportunityOutcomes.open)
                      _OutcomeBadge(outcome: opportunity.outcome),
                  ],
                ),
                if (opportunity.ownerName != null) ...<Widget>[
                  const SizedBox(height: 9),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 15,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          opportunity.ownerName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (moving) ...<Widget>[
                  const SizedBox(height: 10),
                  const LinearProgressIndicator(minHeight: 2),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _OutcomeBadge extends StatelessWidget {
  const _OutcomeBadge({required this.outcome});

  final String outcome;

  @override
  Widget build(BuildContext context) {
    final won = outcome == OpportunityOutcomes.won;
    final color = won ? AppColors.accent : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        won ? 'Ganho' : 'Perdido',
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}
