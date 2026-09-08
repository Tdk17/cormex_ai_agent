import 'dart:async';

import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:agente_vendas_saas/Src/Core/di/service_locator.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/google_copilot/domain/google_copilot_models.dart';
import 'package:agente_vendas_saas/Src/Features/google_copilot/presentation/controllers/google_copilot_controller.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class GoogleCopilotPage extends SignalStatefulWidget {
  const GoogleCopilotPage({super.key});

  @override
  State<GoogleCopilotPage> createState() => _GoogleCopilotPageState();
}

class _GoogleCopilotPageState extends State<GoogleCopilotPage> {
  late final GoogleCopilotController _controller;
  final _adsController = TextEditingController();
  final _ga4Controller = TextEditingController();
  final _searchController = TextEditingController();
  final _budgetController = TextEditingController(text: '0');
  final _budgetChangeController = TextEditingController(text: '0');

  bool _allowAutoPause = false;
  bool _allowAutoBudget = false;
  String? _hydratedEmail;

  @override
  void initState() {
    super.initState();
    _controller = sl<GoogleCopilotController>();
    if (_controller.state.value == ScreenState.initial) {
      unawaited(_controller.load());
    }
  }

  @override
  void dispose() {
    _adsController.dispose();
    _ga4Controller.dispose();
    _searchController.dispose();
    _budgetController.dispose();
    _budgetChangeController.dispose();
    super.dispose();
  }

  void _hydrate(GoogleCopilotConnection? connection) {
    if (connection == null || _hydratedEmail == connection.email) return;
    _hydratedEmail = connection.email;
    _adsController.text = connection.googleAdsCustomerId ?? '';
    _ga4Controller.text = connection.ga4PropertyId ?? '';
    _searchController.text = connection.searchConsoleSiteUrl ?? '';
  }

  Future<void> _connectGoogle() async {
    final uri = await _controller.startOAuth(Uri.base.toString());
    if (!mounted || uri == null) return;
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_self',
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir a autorização do Google.')),
      );
    }
  }

  Future<void> _saveProperties() async {
    FocusScope.of(context).unfocus();
    final ok = await _controller.saveProperties(
      googleAdsCustomerId: _adsController.text,
      ga4PropertyId: _ga4Controller.text,
      searchConsoleSiteUrl: _searchController.text,
    );
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Propriedades Google salvas.')),
      );
    }
  }

  Future<void> _savePolicy() async {
    FocusScope.of(context).unfocus();
    final dailyBudget = double.tryParse(
          _budgetController.text.trim().replaceAll(',', '.'),
        ) ??
        -1;
    final changePercent = double.tryParse(
          _budgetChangeController.text.trim().replaceAll(',', '.'),
        ) ??
        -1;
    final ok = await _controller.savePolicy(
      maxDailyBudget: dailyBudget,
      maxBudgetChangePercent: changePercent,
      allowAutoPause: _allowAutoPause,
      allowAutoBudgetChange: _allowAutoBudget,
    );
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Política de autonomia salva.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final connection = _controller.connection.value;
    final state = _controller.state.value;
    final busy = _controller.busy.value;
    final kpis = _controller.kpis.value;
    final error = _controller.errorMessage.value;
    _hydrate(connection);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 48),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Google Growth Copilot',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Google Ads, GA4 e Search Console em uma única camada de análise e execução supervisionada.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Atualizar',
              onPressed: busy ? null : _controller.load,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 22),
        if (error != null) ...<Widget>[
          _Notice(message: error, error: true),
          const SizedBox(height: 14),
        ],
        if (state == ScreenState.loading && connection == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 80),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...<Widget>[
          _ConnectionCard(
            connection: connection,
            busy: busy,
            onConnect: _connectGoogle,
          ),
          const SizedBox(height: 16),
          if (connection?.connected == true) ...<Widget>[
            _Section(
              title: 'Propriedades Google',
              subtitle:
                  'Defina quais propriedades autorizadas serão usadas pelo agente. Nenhuma senha Google é armazenada no Flutter.',
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 840;
                  final fields = <Widget>[
                    _Field(
                      controller: _adsController,
                      label: 'Google Ads Customer ID',
                      hint: '123-456-7890',
                    ),
                    _Field(
                      controller: _ga4Controller,
                      label: 'GA4 Property ID',
                      hint: '123456789',
                    ),
                    _Field(
                      controller: _searchController,
                      label: 'Search Console',
                      hint: 'https://www.xvclean.com.br/',
                    ),
                  ];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: fields
                              .map((field) => Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: field,
                                    ),
                                  ))
                              .toList(growable: false),
                        )
                      else
                        ...fields.map((field) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: field,
                            )),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: busy ? null : _saveProperties,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Salvar propriedades'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            _KpiSection(kpis: kpis),
            const SizedBox(height: 16),
            _Section(
              title: 'Autonomia e segurança',
              subtitle:
                  'O agente permanece em modo supervisionado. Orçamento e ações automáticas só passam dentro dos limites abaixo.',
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _Field(
                          controller: _budgetController,
                          label: 'Teto diário de orçamento',
                          hint: '500.00',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Field(
                          controller: _budgetChangeController,
                          label: 'Variação automática máxima (%)',
                          hint: '10',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _allowAutoPause,
                    title: const Text('Permitir pausa automática'),
                    subtitle: const Text(
                      'Somente para campanhas não protegidas e quando a política do backend autorizar.',
                    ),
                    onChanged: busy
                        ? null
                        : (value) => setState(() => _allowAutoPause = value),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _allowAutoBudget,
                    title: const Text('Permitir ajuste automático de orçamento'),
                    subtitle: const Text(
                      'A alteração continua limitada por teto absoluto e percentual máximo.',
                    ),
                    onChanged: busy
                        ? null
                        : (value) => setState(() => _allowAutoBudget = value),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: busy ? null : _savePolicy,
                      icon: const Icon(Icons.shield_outlined),
                      label: const Text('Salvar política'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({
    required this.connection,
    required this.busy,
    required this.onConnect,
  });

  final GoogleCopilotConnection? connection;
  final bool busy;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final connected = connection?.connected == true;
    return _Section(
      title: 'Conta Google',
      subtitle: connected
          ? 'A conta está autorizada via OAuth 2.0.'
          : 'Conecte a conta Google que possui acesso às propriedades do cliente.',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: (connected ? Colors.green : Colors.orange).withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          connected ? 'Conectado' : 'Desconectado',
          style: TextStyle(
            color: connected ? Colors.green.shade700 : Colors.orange.shade800,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 25,
            backgroundColor: const Color(0xFF4285F4).withValues(alpha: 0.10),
            child: const Icon(Icons.g_mobiledata_rounded, size: 36, color: Color(0xFF4285F4)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              connected
                  ? (connection?.email ?? 'Conta Google autorizada')
                  : 'Nenhuma conta autorizada',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          FilledButton.icon(
            onPressed: busy ? null : onConnect,
            icon: busy
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.link_rounded),
            label: Text(connected ? 'Reconectar' : 'Conectar Google'),
          ),
        ],
      ),
    );
  }
}

class _KpiSection extends StatelessWidget {
  const _KpiSection({required this.kpis});

  final GoogleCopilotKpis? kpis;

  @override
  Widget build(BuildContext context) {
    final adsRows = _extractAdsRows(kpis?.googleAds);
    return _Section(
      title: 'Visão dos últimos 30 dias',
      subtitle: 'Dados retornados pelas APIs oficiais. Sem mocks.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              _MetricCard(
                label: 'Campanhas lidas',
                value: kpis == null ? '—' : adsRows.length.toString(),
                icon: Icons.ads_click_rounded,
              ),
              _MetricCard(
                label: 'Google Ads',
                value: kpis?.googleAds == null ? 'Pendente' : 'Ativo',
                icon: Icons.campaign_outlined,
              ),
              _MetricCard(
                label: 'GA4',
                value: kpis?.ga4 == null ? 'Pendente' : 'Ativo',
                icon: Icons.analytics_outlined,
              ),
              _MetricCard(
                label: 'Search Console',
                value: kpis?.searchConsole == null ? 'Pendente' : 'Ativo',
                icon: Icons.search_rounded,
              ),
            ],
          ),
          if (kpis == null) ...<Widget>[
            const SizedBox(height: 14),
            const LinearProgressIndicator(),
          ],
          if (kpis?.warnings.isNotEmpty == true) ...<Widget>[
            const SizedBox(height: 14),
            _Notice(message: kpis!.warnings.join(' • '), error: false),
          ],
        ],
      ),
    );
  }

  static List<dynamic> _extractAdsRows(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map && raw['items'] is List) return raw['items'] as List;
    return const <dynamic>[];
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
                  ],
                ),
              ),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: 16),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message, required this.error});

  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final color = error ? AppColors.danger : Colors.orange.shade800;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(message, style: TextStyle(color: color, fontSize: 12, height: 1.4)),
    );
  }
}
