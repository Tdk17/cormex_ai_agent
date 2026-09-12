import 'dart:async';

import 'package:agente_vendas_saas/Src/Features/acquisition/presentation/pages/acquisition_campaign_detail_page.dart';
import 'package:agente_vendas_saas/Src/Features/acquisition/presentation/pages/acquisition_page.dart';
import 'package:agente_vendas_saas/Src/Features/acquisition/presentation/pages/acquisition_wizard_page.dart';
import 'package:agente_vendas_saas/Src/Features/agent/presentation/pages/agent_settings_page.dart';
import 'package:agente_vendas_saas/Src/Features/agent/presentation/pages/agent_test_page.dart';
import 'package:agente_vendas_saas/Src/Features/agent/presentation/pages/operational_agent_page.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/pages/forgot_password_page.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/pages/login_page.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/pages/register_page.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/pages/splash_page.dart';
import 'package:agente_vendas_saas/Src/Features/billing/presentation/pages/billing_page.dart';
import 'package:agente_vendas_saas/Src/Features/conversations/presentation/pages/conversations_page.dart';
import 'package:agente_vendas_saas/Src/Features/crm/accounts/presentation/pages/accounts_page.dart';
import 'package:agente_vendas_saas/Src/Features/crm/activities/presentation/pages/activities_page.dart';
import 'package:agente_vendas_saas/Src/Features/crm/customers/presentation/pages/customers_page.dart';
import 'package:agente_vendas_saas/Src/Features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:agente_vendas_saas/Src/Features/followups/presentation/pages/followups_page.dart';
import 'package:agente_vendas_saas/Src/Features/integrations/presentation/pages/integrations_page.dart';
import 'package:agente_vendas_saas/Src/Features/knowledge/presentation/pages/knowledge_page.dart';
import 'package:agente_vendas_saas/Src/Features/landing/presentation/pages/landing_page.dart';
import 'package:agente_vendas_saas/Src/Features/leads/presentation/pages/lead_detail_page.dart';
import 'package:agente_vendas_saas/Src/Features/leads/presentation/pages/lead_form_page.dart';
import 'package:agente_vendas_saas/Src/Features/leads/presentation/pages/lead_import_page.dart';
import 'package:agente_vendas_saas/Src/Features/leads/presentation/pages/leads_list_page.dart';
import 'package:agente_vendas_saas/Src/Features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:agente_vendas_saas/Src/Features/pipeline/presentation/pages/opportunity_detail_page.dart';
import 'package:agente_vendas_saas/Src/Features/pipeline/presentation/pages/opportunity_form_page.dart';
import 'package:agente_vendas_saas/Src/Features/pipeline/presentation/pages/pipeline_page.dart';
import 'package:agente_vendas_saas/Src/Features/settings/presentation/pages/settings_page.dart';
import 'package:agente_vendas_saas/Src/Features/shared/presentation/pages/app_shell.dart';
import 'package:agente_vendas_saas/Src/Features/team/presentation/pages/team_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals.dart';

class AppRouter {
  AppRouter(this._authController) {
    _refresh = _RouterRefresh(_authController);
    router = GoRouter(
      initialLocation: '/',
      refreshListenable: _refresh,
      redirect: _redirect,
      routes: <RouteBase>[
        GoRoute(path: '/', builder: (_, _) => const LandingPage()),
        GoRoute(path: '/splash', builder: (_, _) => const SplashPage()),
        GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
        GoRoute(path: '/register', builder: (_, _) => const RegisterPage()),
        GoRoute(
          path: '/forgot-password',
          builder: (_, _) => const ForgotPasswordPage(),
        ),
        GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingPage()),
        ShellRoute(
          builder: (BuildContext context, GoRouterState state, Widget child) {
            return AppShell(child: child);
          },
          routes: <RouteBase>[
            GoRoute(path: '/dashboard', builder: (_, _) => const DashboardPage()),
            _leadsRoute('/crm/leads'),
            GoRoute(
              path: '/crm/customers',
              builder: (_, _) => const CustomersPage(),
            ),
            GoRoute(
              path: '/crm/accounts',
              builder: (_, _) => const AccountsPage(),
            ),
            _pipelineRoute('/crm/pipeline'),
            GoRoute(
              path: '/crm/activities',
              builder: (_, _) => const ActivitiesPage(),
            ),
            _conversationsRoute('/crm/conversations'),
            _agentRoute('/automation/agent'),
            GoRoute(
              path: '/automation/followups',
              builder: (_, _) => const FollowUpsPage(),
            ),
            GoRoute(
              path: '/acquisition',
              builder: (_, _) => const AcquisitionPage(),
              routes: <RouteBase>[
                GoRoute(
                  path: 'new',
                  builder: (_, _) => const AcquisitionWizardPage(),
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
            GoRoute(
              path: '/integrations',
              builder: (_, _) => const IntegrationsPage(),
            ),
            GoRoute(
              path: '/knowledge',
              builder: (_, _) => const KnowledgePage(),
            ),
            GoRoute(
              path: '/team',
              builder: (_, _) => const TeamPage(),
            ),
            GoRoute(
              path: '/billing',
              builder: (_, _) => const BillingPage(),
            ),
            GoRoute(
              path: '/settings',
              builder: (_, _) => const SettingsPage(),
            ),
            _legacyLeadsRoute(),
            _legacyPipelineRoute(),
            _legacyConversationsRoute(),
            _legacyAgentRoute(),
            GoRoute(
              path: '/followups',
              redirect: (_, _) => '/automation/followups',
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
              Text(
                'Página não encontrada',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () => context.go('/'),
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
    final atLanding = path == '/';
    final atSplash = path == '/splash';
    final atAuth =
        path == '/login' || path == '/register' || path == '/forgot-password';
    final atOnboarding = path == '/onboarding';
    final publicRoute = atLanding || atAuth;

    if (atLanding) return null;

    if (status == AuthStatus.initial || status == AuthStatus.loading) {
      return publicRoute || atSplash ? null : '/splash';
    }

    if (session == null) {
      return publicRoute ? null : '/login';
    }

    if (!session.hasWorkspace) {
      return atOnboarding ? null : '/onboarding';
    }

    if (atSplash || atAuth || atOnboarding) return '/dashboard';
    return null;
  }

  static GoRoute _leadsRoute(String path) {
    return GoRoute(
      path: path,
      builder: (_, _) => const LeadsListPage(),
      routes: <RouteBase>[
        GoRoute(path: 'new', builder: (_, _) => const LeadFormPage()),
        GoRoute(path: 'import', builder: (_, _) => const LeadImportPage()),
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
    );
  }

  static GoRoute _pipelineRoute(String path) {
    return GoRoute(
      path: path,
      builder: (_, _) => const PipelinePage(),
      routes: <RouteBase>[
        GoRoute(path: 'new', builder: (_, _) => const OpportunityFormPage()),
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
    );
  }

  static GoRoute _conversationsRoute(String path) {
    return GoRoute(
      path: path,
      builder: (_, _) => const ConversationsPage(),
      routes: <RouteBase>[
        GoRoute(
          path: ':conversationId',
          builder: (_, GoRouterState state) => ConversationsPage(
            conversationId: state.pathParameters['conversationId']!,
          ),
        ),
      ],
    );
  }

  static GoRoute _agentRoute(String path) {
    return GoRoute(
      path: path,
      builder: (_, _) => const AgentSettingsPage(),
      routes: <RouteBase>[
        GoRoute(path: 'test', builder: (_, _) => const AgentTestPage()),
        GoRoute(
          path: 'operations',
          builder: (_, _) => const OperationalAgentPage(),
        ),
      ],
    );
  }

  static GoRoute _legacyLeadsRoute() {
    return GoRoute(
      path: '/leads',
      redirect: (_, _) => '/crm/leads',
      routes: <RouteBase>[
        GoRoute(path: 'new', redirect: (_, _) => '/crm/leads/new'),
        GoRoute(path: 'import', redirect: (_, _) => '/crm/leads/import'),
        GoRoute(
          path: ':leadId',
          redirect: (_, GoRouterState state) =>
              '/crm/leads/${state.pathParameters['leadId']}',
          routes: <RouteBase>[
            GoRoute(
              path: 'edit',
              redirect: (_, GoRouterState state) =>
                  '/crm/leads/${state.pathParameters['leadId']}/edit',
            ),
          ],
        ),
      ],
    );
  }

  static GoRoute _legacyPipelineRoute() {
    return GoRoute(
      path: '/pipeline',
      redirect: (_, _) => '/crm/pipeline',
      routes: <RouteBase>[
        GoRoute(path: 'new', redirect: (_, _) => '/crm/pipeline/new'),
        GoRoute(
          path: ':opportunityId',
          redirect: (_, GoRouterState state) =>
              '/crm/pipeline/${state.pathParameters['opportunityId']}',
          routes: <RouteBase>[
            GoRoute(
              path: 'edit',
              redirect: (_, GoRouterState state) =>
                  '/crm/pipeline/${state.pathParameters['opportunityId']}/edit',
            ),
          ],
        ),
      ],
    );
  }

  static GoRoute _legacyConversationsRoute() {
    return GoRoute(
      path: '/conversations',
      redirect: (_, _) => '/crm/conversations',
      routes: <RouteBase>[
        GoRoute(
          path: ':conversationId',
          redirect: (_, GoRouterState state) =>
              '/crm/conversations/${state.pathParameters['conversationId']}',
        ),
      ],
    );
  }

  static GoRoute _legacyAgentRoute() {
    return GoRoute(
      path: '/agent',
      redirect: (_, _) => '/automation/agent',
      routes: <RouteBase>[
        GoRoute(path: 'test', redirect: (_, _) => '/automation/agent/test'),
        GoRoute(
          path: 'operations',
          redirect: (_, _) => '/automation/agent/operations',
        ),
      ],
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
