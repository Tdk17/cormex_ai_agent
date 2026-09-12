import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:agente_vendas_saas/Src/Core/di/service_locator.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';

class SettingsPage extends SignalWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = sl<AuthController>();
    final session = authController.session.value;
    final workspace = session?.selectedWorkspace;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 40),
      children: <Widget>[
        Text('Configurações', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        const Text(
          'Empresa, perfil, segurança e integrações do workspace.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Empresa', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                _SettingRow(
                  icon: Icons.apartment_outlined,
                  label: 'Workspace',
                  value: workspace?.name ?? 'Não selecionado',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Perfil', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                _SettingRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Nome',
                  value: session?.user.name ?? 'Usuário',
                ),
                const Divider(height: 28),
                _SettingRow(
                  icon: Icons.mail_outline_rounded,
                  label: 'E-mail',
                  value: session?.user.email ?? '—',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Administração', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text(
                  'Use os módulos abaixo para administrar pessoas e conexões externas.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: () => context.go('/team'),
                      icon: const Icon(Icons.group_outlined),
                      label: const Text('Gerenciar equipe'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/integrations'),
                      icon: const Icon(Icons.hub_outlined),
                      label: const Text('Gerenciar integrações'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/billing'),
                      icon: const Icon(Icons.credit_card_outlined),
                      label: const Text('Plano e uso'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Encerrar sessão'),
            subtitle: const Text('Sai da conta neste dispositivo.'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: authController.signOut,
          ),
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 12),
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
    );
  }
}
