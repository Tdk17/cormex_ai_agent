import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:agente_vendas_saas/Src/Shared/components/app_brand.dart';
import 'package:flutter/material.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.child,
    required this.title,
    required this.subtitle,
  });

  final Widget child;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final desktop = constraints.maxWidth >= 940;
            if (!desktop) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const AppBrand(),
                        const SizedBox(height: 46),
                        _Header(title: title, subtitle: subtitle),
                        const SizedBox(height: 30),
                        child,
                      ],
                    ),
                  ),
                ),
              );
            }

            return Row(
              children: <Widget>[
                const Expanded(flex: 11, child: _AuthHero()),
                Expanded(
                  flex: 9,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 44),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 470),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            _Header(title: title, subtitle: subtitle),
                            const SizedBox(height: 30),
                            child,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _AuthHero extends StatelessWidget {
  const _AuthHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(18),
      padding: const EdgeInsets.all(54),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF0A554E), Color(0xFF0B6B61), Color(0xFF123A4A)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const AppBrand(light: true),
          const Spacer(),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 26),
          Text(
            'Mais conversas.\nMais oportunidades.\nMais vendas.',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  height: 1.12,
                  fontSize: 42,
                ),
          ),
          const SizedBox(height: 18),
          Text(
            'Organize seus leads e deixe a IA trabalhar junto com sua equipe comercial, 24 horas por dia.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.76),
                  height: 1.55,
                ),
          ),
          const SizedBox(height: 34),
          const Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              _HeroPill(icon: Icons.bolt_rounded, label: 'Follow-up automático'),
              _HeroPill(icon: Icons.insights_rounded, label: 'Pipeline inteligente'),
              _HeroPill(icon: Icons.security_rounded, label: 'Dados isolados'),
            ],
          ),
          const Spacer(),
          Text(
            'Sua operação comercial em um só lugar.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.66),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(width: 7),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
