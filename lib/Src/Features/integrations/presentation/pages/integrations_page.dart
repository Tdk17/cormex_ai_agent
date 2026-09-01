import 'dart:async';

import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:agente_vendas_saas/Src/Core/api/api_exception.dart';
import 'package:agente_vendas_saas/Src/Core/di/service_locator.dart';
import 'package:agente_vendas_saas/Src/Features/acquisition/domain/acquisition_contracts.dart';
import 'package:agente_vendas_saas/Src/Features/acquisition/domain/acquisition_repository.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class IntegrationsPage extends StatefulWidget {
  const IntegrationsPage({super.key});

  @override
  State<IntegrationsPage> createState() => _IntegrationsPageState();
}

class _IntegrationsPageState extends State<IntegrationsPage> {
  late final AcquisitionRepository _repository;
  late final AuthController _authController;

  bool _loading = true;
  bool _connecting = false;
  GoogleAdsConnectionStatus? _googleAds;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = sl<AcquisitionRepository>();
    _authController = sl<AuthController>();
    unawaited(_loadGoogleAds());
  }

  String? get _workspaceId =>
      _authController.session.value?.selectedWorkspace?.id;

  Future<void> _loadGoogleAds() async {
    final workspaceId = _workspaceId;
    if (workspaceId == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Selecione um workspace antes de conectar o Google Ads.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final status = await _repository.googleAdsConnectionStatus(
        workspaceId: workspaceId,
      );
      if (!mounted) return;
      setState(() {
        _googleAds = status;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.userMessage;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Não foi possível consultar a conexão do Google Ads.';
      });
    }
  }

  Future<void> _connectGoogleAds() async {
    if (_connecting) return;
    final workspaceId = _workspaceId;
    if (workspaceId == null) return;

    setState(() {
      _connecting = true;
      _error = null;
    });

    try {
      final result = await _repository.startGoogleAdsOAuth(
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
      setState(() => _error = error.userMessage);
    } on Object {
      if (!mounted) return;
      setState(() => _error = 'Não foi possível iniciar o login com Google.');
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final connected = _googleAds?.connected == true;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 44),
      children: <Widget>[
        Text('Integrações', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        const Text(
          'Conecte as contas que o CormeX poderá usar para publicar campanhas e receber resultados.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.blue.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.ads_click_rounded,
                          color: AppColors.blue,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Google Ads',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Autorize o CormeX pela página oficial do Google.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StatusBadge(
                        connected: connected,
                        loading: _loading,
                      ),
                    ],
                  ),
                  if (_loading) ...<Widget>[
                    const SizedBox(height: 18),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                  if (!_loading && connected) ...<Widget>[
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.20),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.verified_rounded,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  _googleAds?.accountName?.trim().isNotEmpty == true
                                      ? _googleAds!.accountName!
                                      : 'Conta Google Ads conectada',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (_googleAds?.customerId?.trim().isNotEmpty == true)
                                  Text(
                                    'Customer ID: ${_googleAds!.customerId}',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_error != null) ...<Widget>[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      if (!connected)
                        FilledButton.icon(
                          onPressed: _loading || _connecting
                              ? null
                              : _connectGoogleAds,
                          icon: _connecting
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
                        onPressed: _loading ? null : _loadGoogleAds,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Atualizar status'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Sua senha do Google não passa pelo CormeX. A autorização usa OAuth 2.0; credenciais e tokens de longa duração devem permanecer somente no backend.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.campaign_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Meta Ads',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Facebook e Instagram serão conectados pelo mesmo padrão OAuth.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(connected: false, label: 'Em configuração'),
                ],
              ),
            ),
          ),
        ),
      ],
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
    final text = label ?? (loading ? 'Verificando' : connected ? 'Conectado' : 'Desconectado');
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
