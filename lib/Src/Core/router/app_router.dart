import 'dart:async';

import 'package:agente_vendas_saas/Src/Features/acquisition/presentation/pages/acquisition_campaign_detail_page.dart';
import 'package:agente_vendas_saas/Src/Features/acquisition/presentation/pages/acquisition_page.dart';
import 'package:agente_vendas_saas/Src/Features/acquisition/presentation/pages/acquisition_wizard_page.dart';
import 'package:agente_vendas_saas/Src/Features/agent/presentation/pages/agent_settings_page.dart';
import 'package:agente_vendas_saas/Src/Features/agent/presentation/pages/agent_test_page.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/pages/forgot_password_page.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/pages/login_page.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/pages/register_page.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/pages/splash_page.dart';
import 'package:agente_vendas_saas/Src/Features/conversations/presentation/pages/conversations_page.dart';
import 'package:agente_vendas_saas/Src/Features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:agente_vendas_saas/Src/Features/leads/presentation/pages/lead_detail_page.dart';
import 'package:agente_vendas_saas/Src/Features/leads/presentation/pages/lead_form_page.dart';
import 'package:agente_vendas_saas/Src/Features/leads/presentation/pages/lead_import_page.dart';
import 'package:agente_vendas_saas/Src/Features/leads/presentation/pages/leads_list_page.dart';
import 'package:agente_vendas_saas/Src/Features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:agente_vendas_saas/Src/Features/pipeline/presentation/pages/opportunity_detail_page.dart';
import 'package:agente_vendas_saas/Src/Features/pipeline/presentation/pages/opportunity_form_page.dart';
import 'package:agente_vendas_saas/Src/Features/pipeline/presentation/pages/pipeline_page.dart';
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
            GoRoute(
              path: '/acquisition',
              builder: (_, __) => const AcquisitionPage(),
              routes: <RouteBase>[
                GoRoute(
                  path: 'new',
                  builder: (_, __) => const AcquisitionWizardPage(),
                ),
                GoRoute(
                  path: ':campaignId',
                  builder: (_, GoRouterState state) =>
                      AcquisitionCampaignDetailPage(
                    campaignId: state.pathParameters['campaignId']!,
                  ),
                  routes: <RouteBase>[
                    GoRoute(
                      path: 'edit',
                      builder: (_, GoRouterState state) =>
                          AcquisitionWizardPage(
                        campaignId: state.pathParameters['campaignId']!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(path: '/dashboard', builder: (_, __) => const DashboardPage()),
            GoRoute(
              path: '/leads',
              builder: (_, __) => const LeadsListPage(),
              routes: <RouteBase>[
                GoRoute(
                  path: 'new',
                  builder: (_, __) => const LeadFormPage(),
                ),
                GoRoute(
                  path: 'import',
                  builder: (_, __) => const LeadImportPage(),
                ),
                GoRoute(
                  path: ':leadId',
                  builder: (_, GoRouterState state) => LeadDetailPage(
                    leadId: state.pathParameters['leadId']!,
                  ),
                  routes: <RouteBase>[
                    GoRoute(
                      path: 'edit',
                      builder: (_, GoRouterState state) => LeadFormPage(
                        leadId: state.pathParameters['leadId']!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(
              path: '/pipeline',
              builder: (_, __) => const PipelinePage(),
              routes: <RouteBase>[
                GoRoute(
                  path: 'new',
                  builder: (_, __) => const OpportunityFormPage(),
                ),
                GoRoute(
                  path: ':opportunityId',
                  builder: (_, GoRouterState state) => OpportunityDetailPage(
                    opportunityId: state.pathParameters['opportunityId']!,
                  ),
                  routes: <RouteBase>[
                    GoRoute(
                      path: 'edit',
                      builder: (_, GoRouterState state) => OpportunityFormPage(
                        opportunityId: state.pathParameters['opportunityId']!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(
              path: '/conversations',
              builder: (_, __) => const ConversationsPage(),
              routes: <RouteBase>[
                GoRoute(
                  path: ':conversationId',
                  builder: (_, GoRouterState state) => ConversationsPage(
                    conversationId: state.pathParameters['conversationId']!,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: '/agent',
              builder: (_, __) => const AgentSettingsPage(),
              routes: <RouteBase>[
                GoRoute(
                  path: 'test',
                  builder: (_, __) => const AgentTestPage(),
                ),
              ],
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
                onPressed: () => context.go('/acquisition'),
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
    if (atSplash || atAuth || atOnboarding) return '/acquisition';
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
