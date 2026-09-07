import 'dart:async';

import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:agente_vendas_saas/Src/Core/api/api_exception.dart';
import 'package:agente_vendas_saas/Src/Core/di/service_locator.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/acquisition/domain/acquisition_contracts.dart';
import 'package:agente_vendas_saas/Src/Features/acquisition/domain/acquisition_repository.dart';
import 'package:agente_vendas_saas/Src/Features/agent/domain/agent_constants.dart';
import 'package:agente_vendas_saas/Src/Features/agent/presentation/controllers/agent_settings_controller.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:agente_vendas_saas/Src/Features/integrations/domain/integration_models.dart';
import 'package:agente_vendas_saas/Src/Features/integrations/presentation/controllers/integrations_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class IntegrationsPage extends SignalStatefulWidget {
  const IntegrationsPage({super.key});

  @override
  State<IntegrationsPage> createState() => _IntegrationsPageState();
}

class _IntegrationsPageState extends State<IntegrationsPage> {
  late final AcquisitionRepository _acquisitionRepository;
  late final AuthController _authController;
  late final IntegrationsController _integrationsController;
  late final AgentSettingsController _agentController;

  bool _googleLoading = true;
  bool _googleConnecting = false;
  bool _activatingAgent = false;
  GoogleAdsConnectionStatus? _googleAds;
  String? _googleError;

  @override
  void initState() {
    super.initState();
    _acquisitionRepository = sl<AcquisitionRepository>();
    _authController = sl<AuthController>();
    _integrationsController = sl<IntegrationsController>();
    _agentController = sl<AgentSettingsController>();
    if (_integrationsController.state.value == ScreenState.initial) {
      unawaited(_integrationsController.load());
    }
    unawaited(_loadGoogleAds());
  }

  String? get _workspaceId =>
      _authController.session.value?.selectedWorkspace?.id;

  Future<void> _loadGoogleAds() async {
    final workspaceId = _workspaceId;
    if (workspaceId == null) {
      if (!mounted) return;
      setState(() {
        _googleLoading = false;
        _googleError = 'Selecione um workspace antes de conectar o Google Ads.';
      });
      return;
    }

    setState(() {
      _googleLoading = true;
      _googleError = null;
    });

    try {
      final status = await _acquisitionRepository.googleAdsConnectionStatus(
        workspaceId: workspaceId,
      );
      if (!mounted) return;
      setState(() {
        _googleAds = status;
        _googleLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _googleLoading = false;
        _googleError = error.userMessage;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _googleLoading = false;
        _googleError = 'Não foi possível consultar a conexão do Google Ads.';
      });
    }
  }

  Future<void> _connectGoogleAds() async {
    if (_googleConnecting) return;
    final workspaceId = _workspaceId;
    if (workspaceId == null) return;

    setState(() {
      _googleConnecting = true;
      _googleError = null;
    });

    try {
      final result = await _acquisitionRepository.startGoogleAdsOAuth(
        workspaceId: workspaceId,
        returnUrl: Uri.base.toString(),
      );
      final uri = Uri.tryParse(result.authorizationUrl);
      if (uri == null || !uri.hasScheme) {
        throw const ApiException(
          code: 'GOOGLE_OAUTH_ERROR',
          message: 'A URL de autorização do Google é inválida.',
        );
      }
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_self',
      );
      if (!opened) {
        throw const ApiException(
          code: 'GOOGLE_OAUTH_ERROR',
          message: 'Não foi possível abrir o login do Google.',
        );
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _googleError = error.userMessage);
    } on Object {
      if (!mounted) return;
      setState(() => _googleError = 'Não foi possível iniciar o login com Google.');
    } finally {
      if (mounted) setState(() => _googleConnecting = false);
    }
  }

  Future<void> _connectWhatsApp() async {
    final uri = await _integrationsController.startAuthorization(
      provider: IntegrationProviders.whatsapp,
      returnUrl: Uri.base.toString(),
    );
    if (!mounted || uri == null) return;

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_self',
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir a autorização do WhatsApp.')),
      );
    }
  }

  Future<void> _disconnectWhatsApp(IntegrationModel integration) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Desconectar WhatsApp?'),
        content: const Text(
          'Novos envios automáticos serão interrompidos. O histórico de leads e conversas será preservado.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Desconectar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _integrationsController.disconnect(integration);
  }

  Future<void> _activateAiSeller() async {
    if (_activatingAgent || _agentController.isSaving.value) return;
    setState(() => _activatingAgent = true);

    try {
      if (_agentController.state.value == ScreenState.initial ||
          _agentController.state.value == ScreenState.loading) {
        await _agentController.load(force: true);
      }

      _agentController.clearFeedback();
      if (_agentController.name.value.trim().length < 2) {
        _agentController.name.value = 'Clara';
      }
      if (_agentController.objective.value.trim().length < 12) {
        _agentController.objective.value =
            'Atender leads, entender a necessidade, qualificar a oportunidade, responder objeções e conduzir a conversa até o próximo passo comercial ou fechamento.';
      }
      if (_agentController.persona.value.trim().length < 12) {
        _agentController.persona.value =
            'Consultora comercial objetiva, educada e persuasiva. Faz perguntas curtas, entende o contexto do lead, apresenta valor antes de preço e não inventa informações.';
      }
      if (_agentController.productOffer.value.trim().length < 3) {
        _agentController.productOffer.value =
            'Use a oferta principal e a Base de Conhecimento cadastradas neste workspace para apresentar benefícios, condições permitidas e conduzir o lead ao fechamento.';
      }
      if (_agentController.initialMessage.value.trim().length < 5) {
        _agentController.initialMessage.value =
            'Olá! Sou a Clara, consultora virtual da empresa. Vi seu interesse e quero entender o que você precisa para te indicar a melhor opção. O que você está buscando hoje?';
      }
      if (_agentController.rules.value.isEmpty) {
        _agentController.rules.value = const <String>[
          'Nunca inventar preço, desconto, prazo ou condição que não esteja na oferta ou Base de Conhecimento.',
          'Entender a necessidade do lead antes de pressionar pelo fechamento.',
          'Quando não souber uma informação, informar a limitação e encaminhar para atendimento humano.',
          'Respeitar pedido de parar o contato e nunca insistir após opt-out.',
        ];
      }
      if (_agentController.qualificationQuestions.value.isEmpty) {
        _agentController.qualificationQuestions.value = const <String>[
          'O que você está buscando resolver ou comprar agora?',
          'Qual é sua principal prioridade na decisão?',
          'Existe um prazo para tomar a decisão?',
        ];
      }

      _agentController.tone.value = AgentTones.persuasive;
      _agentController.mode.value = AgentModes.auto;
      _agentController.isActive.value = true;
      _agentController.allowPricePresentation.value = true;
      _agentController.allowFollowUp.value = true;
      _agentController.handoffOnRequest.value = true;

      final saved = await _agentController.save();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saved
                ? 'IA vendedora ativada em modo automático. Abra o teste para conversar com ela como se fosse um lead.'
                : (_agentController.errorMessage.value ??
                    'Não foi possível ativar a IA vendedora.'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _activatingAgent = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final whatsapp =
        _integrationsController.provider(IntegrationProviders.whatsapp);
    final whatsappConnected = whatsapp?.connected == true;
    final whatsappBusy = _integrationsController.busyProvider.value ==
        IntegrationProviders.whatsapp;
    final aiActive = _agentController.isActive.value &&
        _agentController.mode.value == AgentModes.auto;
    final googleConnected = _googleAds?.connected == true;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 48),
      children: <Widget>[
        Text(
          'Integrações e canais de venda',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        const Text(
          'Conecte o canal de atendimento, ative a IA e faça um teste de venda antes de colocar a automação em produção.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        _AiSellerCard(
          active: aiActive,
          saving: _activatingAgent || _agentController.isSaving.value,
          errorMessage: _agentController.errorMessage.value,
          onActivate: _activateAiSeller,
          onConfigure: () => context.go('/automation/agent'),
          onTest: () => context.go('/automation/agent/test'),
        ),
        const SizedBox(height: 16),
        _WhatsAppCard(
          integration: whatsapp,
          loading: _integrationsController.state.value == ScreenState.loading,
          busy: whatsappBusy,
          controllerError: _integrationsController.errorMessage.value,
          correlationId: _integrationsController.correlationId.value,
          onConnect: _connectWhatsApp,
          onRefresh: () => _integrationsController.load(force: true),
          onDisconnect: whatsapp == null
              ? null
              : () => _disconnectWhatsApp(whatsapp),
          onOpenConversations: whatsappConnected
              ? () => context.go('/crm/conversations')
              : null,
        ),
        const SizedBox(height: 16),
        const _EmailCard(),
        const SizedBox(height: 16),
        _GoogleAdsCard(
          status: _googleAds,
          loading: _googleLoading,
          connecting: _googleConnecting,
          error: _googleError,
          connected: googleConnected,
          onConnect: _connectGoogleAds,
          onRefresh: _loadGoogleAds,
        ),
        const SizedBox(height: 16),
        const _MetaAdsCard(),
      ],
    );
  }
}

class _AiSellerCard extends StatelessWidget {
  const _AiSellerCard({
    required this.active,
    required this.saving,
    required this.errorMessage,
    required this.onActivate,
    required this.onConfigure,
    required this.onTest,
  });

  final bool active;
  final bool saving;
  final String? errorMessage;
  final VoidCallback onActivate;
  final VoidCallback onConfigure;
  final VoidCallback onTest;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.auto_awesome_rounded,
      iconColor: const Color(0xFF7C3AED),
      title: 'IA vendedora',
      subtitle:
          'Ative o agente em modo automático e teste a abordagem no sandbox antes de falar com clientes reais.',
      status: _StatusBadge(
        connected: active,
        label: active ? 'Ativa · modo auto' : 'Inativa',
      ),
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.16),
            ),
          ),
          child: const Text(
            'O teste usa a configuração salva no backend e chama a IA de verdade, mas não envia mensagem para WhatsApp ou e-mail. Assim você consegue avaliar se ela qualifica, contorna objeções e conduz a venda sem risco.',
            style: TextStyle(fontSize: 12, height: 1.45),
          ),
        ),
        if (errorMessage != null) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            style: const TextStyle(color: AppColors.danger, fontSize: 12),
          ),
        ],
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            FilledButton.icon(
              onPressed: saving ? null : onActivate,
              icon: saving
                  ? const SizedBox.square(
                      dimension: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.power_settings_new_rounded),
              label: Text(active ? 'Revalidar IA vendedora' : 'Ativar IA vendedora'),
            ),
            OutlinedButton.icon(
              onPressed: onTest,
              icon: const Icon(Icons.science_outlined),
              label: const Text('Testar venda agora'),
            ),
            TextButton.icon(
              onPressed: onConfigure,
              icon: const Icon(Icons.tune_rounded),
              label: const Text('Configurar oferta'),
            ),
          ],
        ),
      ],
    );
  }
}

class _WhatsAppCard extends StatelessWidget {
  const _WhatsAppCard({
    required this.integration,
    required this.loading,
    required this.busy,
    required this.controllerError,
    required this.correlationId,
    required this.onConnect,
    required this.onRefresh,
    required this.onDisconnect,
    required this.onOpenConversations,
  });

  final IntegrationModel? integration;
  final bool loading;
  final bool busy;
  final String? controllerError;
  final String? correlationId;
  final VoidCallback onConnect;
  final VoidCallback onRefresh;
  final VoidCallback? onDisconnect;
  final VoidCallback? onOpenConversations;

  @override
  Widget build(BuildContext context) {
    final connected = integration?.connected == true;
    final account = integration?.maskedAccount ?? integration?.displayName;
    return _SectionCard(
      icon: Icons.chat_rounded,
      iconColor: const Color(0xFF16A34A),
      title: 'WhatsApp Business',
      subtitle:
          'Conecte pelo fluxo oficial do provedor. Depois a IA poderá iniciar e responder conversas em modo automático.',
      status: _StatusBadge(
        connected: connected,
        loading: loading,
        label: integration == null ? null : _integrationStatusLabel(integration!.status),
      ),
      children: <Widget>[
        if (loading) const LinearProgressIndicator(minHeight: 2),
        if (connected) ...<Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.verified_rounded, color: AppColors.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        integration?.displayName ?? 'WhatsApp conectado',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      if (account != null)
                        Text(
                          account,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      if (integration!.capabilities.isNotEmpty)
                        Text(
                          integration!.capabilities.join(' · '),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (controllerError != null) ...<Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: AppColors.danger.withValues(alpha: 0.16),
              ),
            ),
            child: Text(
              correlationId == null
                  ? controllerError!
                  : '$controllerError\nID: $correlationId',
              style: const TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            if (!connected)
              FilledButton.icon(
                onPressed: loading || busy ? null : onConnect,
                icon: busy
                    ? const SizedBox.square(
                        dimension: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.link_rounded),
                label: const Text('Conectar WhatsApp'),
              ),
            if (connected)
              FilledButton.tonalIcon(
                onPressed: onOpenConversations,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Iniciar venda com IA'),
              ),
            if (connected)
              OutlinedButton.icon(
                onPressed: busy ? null : onConnect,
                icon: const Icon(Icons.sync_lock_rounded),
                label: const Text('Renovar autorização'),
              ),
            OutlinedButton.icon(
              onPressed: loading || busy ? null : onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Atualizar status'),
            ),
            if (connected && onDisconnect != null)
              TextButton.icon(
                onPressed: busy ? null : onDisconnect,
                icon: const Icon(Icons.link_off_rounded),
                label: const Text('Desconectar'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'O CormeX não solicita sua senha do WhatsApp/Meta. Tokens e segredos devem permanecer somente no backend; o front recebe apenas o status sanitizado da conexão.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _EmailCard extends StatelessWidget {
  const _EmailCard();

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      icon: Icons.alternate_email_rounded,
      iconColor: AppColors.blue,
      title: 'E-mail',
      subtitle:
          'O motor de conversas já prevê o canal e-mail, mas o contrato de conexão de integrações ainda não registra um provider de e-mail. Por isso o front não simula uma conexão inexistente.',
      status: _StatusBadge(connected: false, label: 'Backend pendente'),
      children: <Widget>[
        Text(
          'Para envio real por e-mail ainda é necessário registrar no backend o provedor escolhido (Google/Microsoft/SMTP), OAuth/credenciais seguras, renovação e status. O WhatsApp acima já usa o contrato existente e é o canal indicado para o primeiro teste externo.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _GoogleAdsCard extends StatelessWidget {
  const _GoogleAdsCard({
    required this.status,
    required this.loading,
    required this.connecting,
    required this.error,
    required this.connected,
    required this.onConnect,
    required this.onRefresh,
  });

  final GoogleAdsConnectionStatus? status;
  final bool loading;
  final bool connecting;
  final String? error;
  final bool connected;
  final VoidCallback onConnect;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.ads_click_rounded,
      iconColor: AppColors.blue,
      title: 'Google Ads',
      subtitle:
          'Autorize o CormeX pela página oficial do Google para publicar campanhas e receber resultados.',
      status: _StatusBadge(connected: connected, loading: loading),
      children: <Widget>[
        if (loading) const LinearProgressIndicator(minHeight: 2),
        if (!loading && connected) ...<Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status?.accountName?.trim().isNotEmpty == true
                  ? status!.accountName!
                  : 'Conta Google Ads conectada',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (error != null) ...<Widget>[
          Text(
            error!,
            style: const TextStyle(color: AppColors.danger, fontSize: 12),
          ),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            if (!connected)
              FilledButton.icon(
                onPressed: loading || connecting ? null : onConnect,
                icon: connecting
                    ? const SizedBox.square(
                        dimension: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.login_rounded),
                label: const Text('Entrar com Google'),
              ),
            OutlinedButton.icon(
              onPressed: loading ? null : onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Atualizar status'),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetaAdsCard extends StatelessWidget {
  const _MetaAdsCard();

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      icon: Icons.campaign_outlined,
      iconColor: AppColors.primary,
      title: 'Meta Ads',
      subtitle: 'Facebook e Instagram serão conectados pelo fluxo OAuth da Meta.',
      status: _StatusBadge(connected: false, label: 'Em configuração'),
      children: <Widget>[
        Text(
          'A conexão de anúncios da Meta continua separada do WhatsApp Business para evitar misturar permissões de mídia e mensageria.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.children,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget status;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 920),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: iconColor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  status,
                ],
              ),
              if (children.isNotEmpty) ...<Widget>[
                const SizedBox(height: 18),
                ...children,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.connected,
    this.loading = false,
    this.label,
  });

  final bool connected;
  final bool loading;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final color = connected ? AppColors.accent : AppColors.textSecondary;
    final text = label ??
        (loading ? 'Verificando' : connected ? 'Conectado' : 'Desconectado');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _integrationStatusLabel(String status) {
  return switch (status) {
    IntegrationStatuses.connected => 'Conectado',
    IntegrationStatuses.connecting => 'Conectando',
    IntegrationStatuses.authorizationError => 'Autorização expirada',
    IntegrationStatuses.permissionError => 'Permissão necessária',
    IntegrationStatuses.paymentIssue => 'Problema de pagamento',
    IntegrationStatuses.expired => 'Expirado',
    IntegrationStatuses.disabled => 'Desativado',
    _ => 'Desconectado',
  };
}
