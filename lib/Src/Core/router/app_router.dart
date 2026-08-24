import 'dart:async';

import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/pages/forgot_password_page.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/pages/login_page.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/pages/register_page.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/pages/splash_page.dart';
import 'package:agente_vendas_saas/Src/Features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:agente_vendas_saas/Src/Features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:agente_vendas_saas/Src/Features/shared/presentation/pages/app_shell.dart';
import 'package:agente_vendas_saas/Src/Features/shared/presentation/pages/feature_placeholder_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals.dart';

class AppRouter {
  AppRouter(this._authController) {
    _refresh = _RouterRefresh(_authController);
    router = GoRouter(
      initialLocation: '/splash',
      refreshListenable: _refresh,
      redirect: _redirect,
      routes: <RouteBase>[
        GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
        GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
        GoRoute(
          path: '/forgot-password',
          builder: (_, __) => const ForgotPasswordPage(),
        ),
        GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),
        ShellRoute(
          builder: (BuildContext context, GoRouterState state, Widget child) {
            return AppShell(child: child);
          },
          routes: <RouteBase>[
            GoRoute(path: '/dashboard', builder: (_, __) => const DashboardPage()),
            _placeholder(
              '/leads',
              'Leads',
              'Cadastre, importe, filtre e qualifique sua base comercial.',
              Icons.groups_2_outlined,
            ),
            _placeholder(
              '/pipeline',
              'Pipeline',
              'Visualize e movimente oportunidades entre as etapas do funil.',
              Icons.view_kanban_outlined,
            ),
            _placeholder(
              '/conversations',
              'Conversas',
              'Centralize o histórico de cada lead e alterne entre IA e atendimento humano.',
              Icons.forum_outlined,
            ),
            _placeholder(
              '/agent',
              'Agente de IA',
              'Configure persona, objetivo, tom, regras, horários e modo de operação.',
              Icons.auto_awesome_outlined,
            ),
            _placeholder(
              '/knowledge',
              'Base de conhecimento',
              'Gerencie textos, FAQs e arquivos usados para contextualizar o agente.',
              Icons.menu_book_outlined,
            ),
            _placeholder(
              '/followups',
              'Follow-ups e tarefas',
              'Crie cadências, condições e tarefas comerciais programadas.',
              Icons.schedule_send_outlined,
            ),
            _placeholder(
              '/team',
              'Equipe',
              'Convide usuários e gerencie os papéis owner, admin e seller.',
              Icons.group_outlined,
            ),
            _placeholder(
              '/integrations',
              'Integrações',
              'Conecte canais com credenciais mascaradas e acompanhe a sincronização.',
              Icons.hub_outlined,
            ),
            _placeholder(
              '/billing',
              'Plano e uso',
              'Acompanhe consumo, limites e opções de evolução do plano.',
              Icons.credit_card_outlined,
            ),
            _placeholder(
              '/settings',
              'Configurações',
              'Gerencie empresa, perfil, segurança, workspace e sessão.',
              Icons.settings_outlined,
            ),
          ],
        ),
      ],
      errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.explore_off_outlined, size: 48),
              const SizedBox(height: 14),
              Text('Página não encontrada', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Voltar ao início'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  final AuthController _authController;
  late final _RouterRefresh _refresh;
  late final GoRouter router;

  String? _redirect(BuildContext context, GoRouterState state) {
    final status = _authController.status.value;
    final session = _authController.session.value;
    final path = state.uri.path;
    final atSplash = path == '/splash';
    final atAuth = path == '/login' || path == '/register' || path == '/forgot-password';
    final atOnboarding = path == '/onboarding';

    if (status == AuthStatus.initial || status == AuthStatus.loading) {
      return atSplash ? null : '/splash';
    }
    if (session == null) return atAuth ? null : '/login';
    if (!session.hasWorkspace) return atOnboarding ? null : '/onboarding';
    if (atSplash || atAuth || atOnboarding) return '/dashboard';
    return null;
  }

  static GoRoute _placeholder(
    String path,
    String title,
    String description,
    IconData icon,
  ) {
    return GoRoute(
      path: path,
      builder: (_, __) => FeaturePlaceholderPage(
        title: title,
        description: description,
        icon: icon,
      ),
    );
  }
}

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(AuthController controller) {
    _disposeEffect = effect(() {
      controller.status.value;
      controller.session.value;
      scheduleMicrotask(notifyListeners);
    });
  }

  late final void Function() _disposeEffect;

  @override
  void dispose() {
    _disposeEffect();
    super.dispose();
  }
}
