import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:agente_vendas_saas/Src/Features/conversations/presentation/controllers/conversation_thread_controller.dart';
import 'package:agente_vendas_saas/Src/Shared/models/conversation_models.dart';
import 'package:agente_vendas_saas/Src/Shared/models/lead_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';

class LeadContextPanel extends SignalWidget {
  const LeadContextPanel({
    super.key,
    required this.controller,
    this.onClose,
  });

  final ConversationThreadController controller;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final lead = controller.lead.value;
    final conversation = controller.conversation.value;
    final salesContext = controller.salesContext.value;
    final owners = controller.owners.value;

    return ColoredBox(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 10, 12),
            child: Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Contexto comercial',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (lead == null || conversation == null)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
                children: <Widget>[
                  _LeadIdentity(lead: lead),
                  const SizedBox(height: 18),
                  FilledButton.tonalIcon(
                    onPressed: () {
                      final router = GoRouter.of(context);
                      onClose?.call();
                      router.go('/leads/${lead.id}');
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Abrir cadastro do lead'),
                  ),
                  const SizedBox(height: 22),
                  const _SectionTitle(
                    icon: Icons.assignment_ind_outlined,
                    label: 'Responsável',
                  ),
                  const SizedBox(height: 9),
                  _OwnerSelector(
                    controller: controller,
                    conversation: conversation,
                    owners: owners,
                  ),
                  const SizedBox(height: 22),
                  const _SectionTitle(
                    icon: Icons.insights_outlined,
                    label: 'Qualificação',
                  ),
                  const SizedBox(height: 10),
                  _InfoLine(label: 'Status', value: _leadStatus(lead.status)),
                  _InfoLine(label: 'Canal', value: _channelLabel(conversation.channel)),
                  _InfoLine(label: 'Score', value: '${lead.score}/100'),
                  _InfoLine(label: 'Origem', value: lead.source),
                  if (lead.company?.trim().isNotEmpty == true)
                    _InfoLine(label: 'Empresa', value: lead.company!),
                  if (lead.phone?.trim().isNotEmpty == true)
                    _InfoLine(label: 'Telefone', value: lead.phone!),
                  if (lead.email?.trim().isNotEmpty == true)
                    _InfoLine(label: 'E-mail', value: lead.email!),
                  const SizedBox(height: 20),
                  if (lead.tags.isNotEmpty) ...<Widget>[
                    const _SectionTitle(
                      icon: Icons.sell_outlined,
                      label: 'Tags',
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: lead.tags
                          .map(
                            (String tag) => Chip(
                              label: Text(tag),
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 20),
                  ],
                  const _SectionTitle(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Interesse e negociação',
                  ),
                  const SizedBox(height: 10),
                  _ContextBlock(
                    label: 'Produto ou serviço',
                    value: salesContext.product,
                  ),
                  _ContextBlock(
                    label: 'Carrinho / proposta',
                    value: salesContext.cartSummary,
                  ),
                  _ContextBlock(
                    label: 'Histórico resumido',
                    value: salesContext.historySummary,
                  ),
                  _ContextBlock(
                    label: 'Notas',
                    value: salesContext.notes,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LeadIdentity extends StatelessWidget {
  const _LeadIdentity({required this.lead});

  final LeadModel lead;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        CircleAvatar(
          radius: 35,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          foregroundColor: AppColors.primary,
          child: Text(
            _initials(lead.name),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          lead.name.isEmpty ? 'Lead sem nome' : lead.name,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (lead.company?.trim().isNotEmpty == true) ...<Widget>[
          const SizedBox(height: 3),
          Text(
            lead.company!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _OwnerSelector extends SignalWidget {
  const _OwnerSelector({
    required this.controller,
    required this.conversation,
    required this.owners,
  });

  final ConversationThreadController controller;
  final ConversationModel conversation;
  final List<ConversationOwnerModel> owners;

  @override
  Widget build(BuildContext context) {
    final knownOwner = owners.any(
      (ConversationOwnerModel item) => item.id == conversation.assignedUserId,
    );
    return DropdownButtonFormField<String>(
      value: knownOwner ? conversation.assignedUserId : '',
      isExpanded: true,
      decoration: const InputDecoration(
        isDense: true,
        prefixIcon: Icon(Icons.person_outline_rounded),
      ),
      items: <DropdownMenuItem<String>>[
        const DropdownMenuItem<String>(
          value: '',
          child: Text('Sem responsável'),
        ),
        ...owners.map(
          (ConversationOwnerModel owner) => DropdownMenuItem<String>(
            value: owner.id,
            child: Text(owner.name, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: controller.isChangingAssignment.value
          ? null
          : (String? value) =>
              controller.assign(value == null || value.isEmpty ? null : value),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 7),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextBlock extends StatelessWidget {
  const _ContextBlock({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value?.trim().isNotEmpty == true ? value! : 'Não informado',
            style: const TextStyle(fontSize: 12, height: 1.35),
          ),
        ],
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'L';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String _leadStatus(String value) => switch (value) {
      'new' => 'Novo',
      'qualified' => 'Qualificado',
      'negotiation' => 'Em negociação',
      'won' => 'Ganho',
      'lost' => 'Perdido',
      _ => value,
    };

String _channelLabel(String value) => switch (value) {
      'whatsapp' => 'WhatsApp',
      'instagram' => 'Instagram',
      'webchat' => 'Webchat',
      'email' => 'E-mail',
      _ => value,
    };
