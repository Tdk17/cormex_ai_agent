import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CrmModulePage extends StatelessWidget {
  const CrmModulePage({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.emptyTitle,
    required this.emptyDescription,
    required this.primaryLabel,
    required this.primaryRoute,
  });

  final String title;
  final String description;
  final IconData icon;
  final String emptyTitle;
  final String emptyDescription;
  final String primaryLabel;
  final String primaryRoute;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 40),
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          description,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
            child: Column(
              children: <Widget>[
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(icon, size: 32, color: AppColors.primary),
                ),
                const SizedBox(height: 18),
                Text(
                  emptyTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Text(
                    emptyDescription,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: () => context.go(primaryRoute),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(primaryLabel),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
