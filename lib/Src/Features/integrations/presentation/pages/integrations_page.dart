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
  bool _googleAccountsLoading = false;
  bool _googleMutating = false;
  bool _activatingAgent = false;
  GoogleAdsConnectionStatus? _googleAds;
  List<GoogleAdsAccount> _googleAccounts = const <GoogleAdsAccount>[];
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
        _googleError = 'Selecione uma empresa antes de conectar o Google Ads.';
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
      if (status.status == 'account_selection_required') {
        await _loadGoogleAdsAccounts();
      }
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

  Future<void> _loadGoogleAdsAccounts() async {
    final workspaceId = _workspaceId;
    if (workspaceId == null || _googleAccountsLoading) return;
    setState(() {
      _googleAccountsLoading = true;
      _googleError = null;
    });
    try {
      final accounts = await _acquisitionRepository.googleAdsAccounts(
        workspaceId: workspaceId,
      );
      if (!mounted) return;
      setState(() {
        _googleAccounts = accounts.where((account) => account.selectable).toList(growable: false);
        _googleAccountsLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _googleAccountsLoading = false;
        _googleError = error.userMessage;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _googleAccountsLoading = false;
        _googleError = 'Não foi possível carregar as contas de anúncio disponíveis.';
      });
    }
  }

  Future<void> _selectGoogleAdsAccount(GoogleAdsAccount account) async {
    final workspaceId = _workspaceId;
    if (workspaceId == null || _googleMutating) return;
    setState(() {
      _googleMutating = true;
      _googleError = null;
    });
    try {
      final status = await _acquisitionRepository.selectGoogleAdsAccount(
        workspaceId: workspaceId,
        customerId: account.customerId,
      );
      if (!mounted) return;
      setState(() {
        _googleAds = status;
        _googleAccounts = const <GoogleAdsAccount>[];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta Google Ads selecionada com sucesso.')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _googleError = error.userMessage);
    } on Object {
      if (!mounted) return;
      setState(() => _googleError = 'Não foi possível selecionar a conta Google Ads.');
    } finally {
      if (mounted) setState(() => _googleMutating = false);
    }
  }

  Future<void> _disconnectGoogleAds() async {
    final workspaceId = _workspaceId;
    if (workspaceId == null || _googleMutating) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desconectar Google Ads?'),
        content: const Text(
          'A publicação e a leitura de resultados do Google Ads serão interrompidas até uma nova autorização.',
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

    setState(() {
      _googleMutating = true;
      _googleError = null;
    });
    try {
      final status = await _acquisitionRepository.disconnectGoogleAds(
        workspaceId: workspaceId,
      );
      if (!mounted) return;
      setState(() {
        _googleAds = status;
        _googleAccounts = const <GoogleAdsAccount>[];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Ads desconectado.')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _googleError = error.userMessage);
    } on Object {
      if (!mounted) return;
      setState(() => _googleError = 'Não foi possível desconectar o Google Ads.');
    } finally {
      if (mounted) setState(() => _googleMutating = false);
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
      builder: (context) => AlertDialog(
        title: const Text('Desconectar WhatsApp?'),
        content: const Text(
          'Novos envios automáticos serão interrompidos. O histórico de leads e conversas será preservado.',
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Desconectar')),
        ],
      ),
    );
    if (confirmed == true) await _integrationsController.disconnect(integration);
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
            'Use a oferta principal e a Base de Conhecimento cadastradas neste workspace para apresentar benefícios e conduzir o lead ao fechamento.';
      }
      if (_agentController.initialMessage.value.trim().length < 5) {
        _agentController.initialMessage.value =
            'Olá! Sou a Clara, consultora virtual da empresa. Vi seu interesse e quero entender o que você precisa para te indicar a melhor opção.';
      }
      if (_agentController.rules.value.isEmpty) {
        _agentController.rules.value = const <String>[
          'Nunca inventar preço, desconto, prazo ou condição que não esteja na oferta ou Base de Conhecimento.',
          'Entender a necessidade do lead antes de pressionar pelo fechamento.',
          'Quando não souber uma informação, encaminhar para atendimento humano.',
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
                ? 'IA vendedora ativada em modo automático.'
                : (_agentController.errorMessage.value ?? 'Não foi possível ativar a IA vendedora.'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _activatingAgent = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final whatsapp = _integrationsController.provider(IntegrationProviders.whatsapp);
    final whatsappConnected = whatsapp?.connected == true;
    final whatsappBusy = _integrationsController.busyProvider.value == IntegrationProviders.whatsapp;
    final aiActive = _agentController.isActive.value && _agentController.mode.value == AgentModes.auto;
    final googleConnected = _googleAds?.connected == true;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 48),
      children: <Widget>[
        Text('Integrações e canais de venda', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        const Text(
          'Conecte canais, anúncios e a IA usando somente dados necessários para operação.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        _IntegrationCard(
          icon: Icons.auto_awesome_rounded,
          iconColor: const Color(0xFF7C3AED),
          title: 'IA vendedora',
          subtitle: 'Ative e teste o agente comercial antes de usar canais externos.',
          status: _StatusBadge(connected: aiActive, label: aiActive ? 'Ativa · modo auto' : 'Inativa'),
          children: <Widget>[
            if (_agentController.errorMessage.value != null)
              _ErrorBox(message: _agentController.errorMessage.value!),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: _activatingAgent || _agentController.isSaving.value ? null : _activateAiSeller,
                  icon: const Icon(Icons.power_settings_new_rounded),
                  label: Text(aiActive ? 'Revalidar IA' : 'Ativar IA vendedora'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/automation/agent/test'),
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('Testar venda'),
                ),
                TextButton.icon(
                  onPressed: () => context.go('/automation/agent'),
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('Configurar'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _IntegrationCard(
          icon: Icons.chat_rounded,
          iconColor: const Color(0xFF16A34A),
          title: 'WhatsApp Business',
          subtitle: 'Autorize sua conta pela Meta para permitir atendimento e automações.',
          status: _StatusBadge(
            connected: whatsappConnected,
            loading: _integrationsController.state.value == ScreenState.loading,
            label: whatsapp == null ? null : _integrationStatusLabel(whatsapp.status),
          ),
          children: <Widget>[
            if (whatsappConnected)
              _SafeAccountBox(
                title: whatsapp?.displayName ?? 'WhatsApp conectado',
                subtitle: whatsapp?.maskedAccount,
              ),
            if (_integrationsController.errorMessage.value != null)
              _ErrorBox(message: _integrationsController.errorMessage.value!),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                if (!whatsappConnected)
                  FilledButton.icon(
                    onPressed: whatsappBusy ? null : _connectWhatsApp,
                    icon: const Icon(Icons.link_rounded),
                    label: const Text('Conectar WhatsApp'),
                  ),
                if (whatsappConnected)
                  FilledButton.tonalIcon(
                    onPressed: () => context.go('/crm/conversations'),
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Iniciar venda com IA'),
                  ),
                OutlinedButton.icon(
                  onPressed: whatsappBusy ? null : () => _integrationsController.load(force: true),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Atualizar status'),
                ),
                if (whatsappConnected && whatsapp != null)
                  TextButton.icon(
                    onPressed: whatsappBusy ? null : () => _disconnectWhatsApp(whatsapp),
                    icon: const Icon(Icons.link_off_rounded),
                    label: const Text('Desconectar'),
                  ),
              ],
            ),
            const Text(
              'Tokens, credenciais e identificadores técnicos permanecem no backend e não são exibidos nesta tela.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _IntegrationCard(
          icon: Icons.ads_click_rounded,
          iconColor: AppColors.blue,
          title: 'Google Ads',
          subtitle: 'Autorize, escolha a conta anunciante e gerencie a conexão usada pelas campanhas.',
          status: _StatusBadge(
            connected: googleConnected,
            loading: _googleLoading,
            label: _googleAds?.status == 'account_selection_required' ? 'Escolha a conta' : null,
          ),
          children: <Widget>[
            if (_googleLoading) const LinearProgressIndicator(minHeight: 2),
            if (googleConnected)
              _SafeAccountBox(
                title: _googleAds?.accountName?.trim().isNotEmpty == true
                    ? _googleAds!.accountName!
                    : 'Conta Google Ads conectada',
              ),
            if (_googleError != null) _ErrorBox(message: _googleError!),
            if (_googleAds?.status == 'account_selection_required' || _googleAccounts.isNotEmpty) ...<Widget>[
              const Text(
                'Selecione a conta de anunciante que o CormeX deve usar. Contas administradoras não são disponibilizadas para seleção.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              if (_googleAccountsLoading) const LinearProgressIndicator(minHeight: 2),
              if (!_googleAccountsLoading && _googleAccounts.isEmpty)
                OutlinedButton.icon(
                  onPressed: _googleMutating ? null : _loadGoogleAdsAccounts,
                  icon: const Icon(Icons.list_alt_rounded),
                  label: const Text('Carregar contas'),
                ),
              for (final account in _googleAccounts)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.campaign_rounded),
                  title: Text(account.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: account.currency == null ? null : Text('Moeda: ${account.currency}'),
                  trailing: FilledButton(
                    onPressed: _googleMutating ? null : () => _selectGoogleAdsAccount(account),
                    child: const Text('Selecionar'),
                  ),
                ),
            ],
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                if (!googleConnected && _googleAds?.status != 'account_selection_required')
                  FilledButton.icon(
                    onPressed: _googleLoading || _googleConnecting ? null : _connectGoogleAds,
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Entrar com Google'),
                  ),
                OutlinedButton.icon(
                  onPressed: _googleLoading ? null : _loadGoogleAds,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Atualizar status'),
                ),
                if (googleConnected)
                  TextButton.icon(
                    onPressed: _googleMutating ? null : _disconnectGoogleAds,
                    icon: const Icon(Icons.link_off_rounded),
                    label: const Text('Desconectar'),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _IntegrationCard(
          icon: Icons.alternate_email_rounded,
          iconColor: AppColors.blue,
          title: 'E-mail',
          subtitle: 'O canal existe no motor de conversas, mas a conexão do provedor ainda depende de backend.',
          status: _StatusBadge(connected: false, label: 'Backend pendente'),
          children: <Widget>[],
        ),
        const SizedBox(height: 16),
        const _IntegrationCard(
          icon: Icons.campaign_outlined,
          iconColor: AppColors.primary,
          title: 'Meta Ads',
          subtitle: 'Facebook e Instagram permanecem separados do WhatsApp Business.',
          status: _StatusBadge(connected: false, label: 'Em configuração'),
          children: <Widget>[],
        ),
      ],
    );
  }
}

class _IntegrationCard extends StatelessWidget {
  const _IntegrationCard({
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
    return Card(
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
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.35),
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
              ...children.expand((widget) => <Widget>[widget, const SizedBox(height: 12)]),
            ],
          ],
        ),
      ),
    );
  }
}

class _SafeAccountBox extends StatelessWidget {
  const _SafeAccountBox({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          if (subtitle?.trim().isNotEmpty == true)
            Text(subtitle!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.16)),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.connected, this.loading = false, this.label});

  final bool connected;
  final bool loading;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final color = connected ? AppColors.accent : AppColors.textSecondary;
    final text = label ?? (loading ? 'Verificando' : connected ? 'Conectado' : 'Desconectado');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
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
