import 'dart:async';

import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:agente_vendas_saas/Src/Core/di/service_locator.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/team/domain/team_models.dart';
import 'package:agente_vendas_saas/Src/Features/team/presentation/controllers/team_controller.dart';
import 'package:agente_vendas_saas/Src/Shared/components/form_error_banner.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signals/signals_flutter.dart';

class TeamPage extends SignalStatefulWidget {
  const TeamPage({super.key});

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  late final TeamController controller;

  @override
  void initState() {
    super.initState();
    controller = sl<TeamController>();
    if (controller.state.value == ScreenState.initial) {
      unawaited(controller.load());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = controller.state.value;
    final members = controller.members.value;
    final invitations = controller.invitations.value;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 48),
      children: <Widget>[
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Equipe', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 5),
                const Text(
                  'Gerencie quem pode configurar, acompanhar e atender no workspace.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
            if (controller.canManage)
              FilledButton.icon(
                onPressed: controller.isMutating.value ? null : _showInvite,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Convidar pessoa'),
              ),
          ],
        ),
        if (!controller.canManage) ...<Widget>[
          const SizedBox(height: 16),
          const _InfoBanner(
            icon: Icons.lock_outline_rounded,
            message:
                'Seu papel permite visualizar a equipe, mas somente owner ou admin podem alterá-la.',
          ),
        ],
        if (controller.errorMessage.value != null) ...<Widget>[
          const SizedBox(height: 14),
          FormErrorBanner(
            message: controller.errorMessage.value!,
            correlationId: controller.correlationId.value,
          ),
        ],
        if (controller.successMessage.value != null) ...<Widget>[
          const SizedBox(height: 14),
          _InfoBanner(
            icon: Icons.check_circle_outline_rounded,
            message: controller.successMessage.value!,
            success: true,
          ),
        ],
        const SizedBox(height: 22),
        if (state == ScreenState.loading && members.isEmpty)
          const Padding(
            padding: EdgeInsets.all(64),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (state == ScreenState.error && members.isEmpty)
          Center(
            child: OutlinedButton.icon(
              onPressed: () => controller.load(force: true),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          )
        else ...<Widget>[
          Row(
            children: <Widget>[
              Text('Membros (${members.length})', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton.filledTonal(
                tooltip: 'Atualizar',
                onPressed: () => controller.load(force: true),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (members.isEmpty)
            const _InfoBanner(
              icon: Icons.group_outlined,
              message: 'A API ainda não retornou membros para este workspace.',
            )
          else
            ...members.map(
              (TeamMemberModel member) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _MemberCard(
                  member: member,
                  canManage: controller.canManage,
                  disabled: controller.isMutating.value,
                  onRoleChanged: (String role) =>
                      controller.updateRole(member, role),
                ),
              ),
            ),
          if (invitations.isNotEmpty) ...<Widget>[
            const SizedBox(height: 22),
            Text('Convites pendentes', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            ...invitations.map(
              (TeamInvitationModel invitation) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _InvitationCard(invitation: invitation),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Future<void> _showInvite() async {
    controller.clearFeedback();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => _InviteDialog(controller: controller),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.canManage,
    required this.disabled,
    required this.onRoleChanged,
  });

  final TeamMemberModel member;
  final bool canManage;
  final bool disabled;
  final ValueChanged<String> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    final canEdit = canManage && member.role != 'owner' && !disabled;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 23,
              backgroundColor: AppColors.primary.withValues(alpha: 0.10),
              foregroundColor: AppColors.primary,
              child: Text(_initials(member.name, member.email)),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    member.name.trim().isEmpty ? member.email : member.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    member.email,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  if (member.lastActiveAt != null) ...<Widget>[
                    const SizedBox(height: 3),
                    Text(
                      'Último acesso ${DateFormat('dd/MM/yyyy HH:mm').format(member.lastActiveAt!.toLocal())}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (member.role == 'owner')
              const _RoleBadge(label: 'Proprietário', color: AppColors.primary)
            else
              SizedBox(
                width: 150,
                child: DropdownButtonFormField<String>(
                  initialValue: member.role,
                  decoration: const InputDecoration(isDense: true),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem<String>(value: 'seller', child: Text('Vendedor')),
                  ],
                  onChanged: canEdit
                      ? (String? value) {
                          if (value != null && value != member.role) {
                            onRoleChanged(value);
                          }
                        }
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InvitationCard extends StatelessWidget {
  const _InvitationCard({required this.invitation});
  final TeamInvitationModel invitation;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.mail_outline_rounded)),
        title: Text(invitation.email),
        subtitle: Text(
          'Papel: ${_roleLabel(invitation.role)}${invitation.expiresAt == null ? '' : ' • expira em ${DateFormat('dd/MM/yyyy').format(invitation.expiresAt!.toLocal())}'}',
        ),
        trailing: const _RoleBadge(label: 'Pendente', color: AppColors.warning),
      ),
    );
  }
}

class _InviteDialog extends StatefulWidget {
  const _InviteDialog({required this.controller});
  final TeamController controller;

  @override
  State<_InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends State<_InviteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String _role = 'seller';
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Convidar para a equipe'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-mail'),
                validator: (String? value) {
                  final email = value?.trim() ?? '';
                  return !email.contains('@') || !email.contains('.')
                      ? 'Informe um e-mail válido.'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Papel inicial'),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(
                    value: 'seller',
                    child: Text('Vendedor — atende e opera leads'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'admin',
                    child: Text('Admin — também configura o workspace'),
                  ),
                ],
                onChanged: (String? value) {
                  if (value != null) _role = value;
                },
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _sending ? null : _send,
          icon: _sending
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.send_rounded),
          label: const Text('Enviar convite'),
        ),
      ],
    );
  }

  Future<void> _send() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    final success = await widget.controller.invite(_emailController.text, _role);
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _sending = false;
        _error = widget.controller.errorMessage.value;
      });
    }
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.message,
    this.success = false,
  });
  final IconData icon;
  final String message;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final color = success ? AppColors.accent : AppColors.blue;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: color),
          const SizedBox(width: 9),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

String _initials(String name, String email) {
  final value = name.trim().isEmpty ? email : name;
  final parts = value.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'U';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String _roleLabel(String role) => switch (role) {
      'admin' => 'Admin',
      'owner' => 'Proprietário',
      _ => 'Vendedor',
    };
