import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:agente_vendas_saas/Src/Core/api/api_result.dart';
import 'package:agente_vendas_saas/Src/Core/di/service_locator.dart';
import 'package:agente_vendas_saas/Src/Core/http/endpoints.dart';
import 'package:agente_vendas_saas/Src/Core/http/http_manager.dart';
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
        if (workspace != null) ...<Widget>[
          const SizedBox(height: 14),
          _OperationalHealthCard(workspaceId: workspace.id),
        ],
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

class _OperationalHealthCard extends StatefulWidget {
  const _OperationalHealthCard({required this.workspaceId});

  final String workspaceId;

  @override
  State<_OperationalHealthCard> createState() => _OperationalHealthCardState();
}

class _OperationalHealthCardState extends State<_OperationalHealthCard> {
  bool _loading = true;
  String? _message;
  Map<String, dynamic>? _health;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _OperationalHealthCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workspaceId != widget.workspaceId) _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _message = null;
    });

    final result = await sl<HttpManager>().cloudFunction(
      name: Endpoints.aiOperationsHealth,
      parameters: <String, dynamic>{'workspaceId': widget.workspaceId},
    );
    if (!mounted) return;

    switch (result) {
      case ApiSuccess<Map<String, dynamic>>(:final data):
        setState(() {
          _health = data;
          _loading = false;
        });
      case ApiFailure<Map<String, dynamic>>():
        setState(() {
          _health = null;
          _loading = false;
          _message =
              'Saúde operacional disponível para gestores e administradores quando o serviço estiver acessível.';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sections = _map(_health?['sections']);
    final dependencies = _map(_health?['dependencies']);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Saúde operacional',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Resumo das últimas 24 horas. Credenciais e identificadores técnicos não são exibidos.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Atualizar',
                  onPressed: _loading ? null : _load,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            if (_loading) ...<Widget>[
              const SizedBox(height: 16),
              const LinearProgressIndicator(minHeight: 2),
            ] else if (_message != null) ...<Widget>[
              const SizedBox(height: 14),
              Text(
                _message!,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ] else ...<Widget>[
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _HealthChip(
                    label: 'Respostas da IA',
                    section: _map(sections['aiReplies']),
                  ),
                  _HealthChip(
                    label: 'Follow-ups',
                    section: _map(sections['followups']),
                  ),
                  _HealthChip(
                    label: 'Entregas',
                    section: _map(sections['deliveries']),
                  ),
                  _HealthChip(
                    label: 'Base de conhecimento',
                    section: _map(sections['knowledge']),
                  ),
                  _HealthChip(
                    label: 'Campanhas',
                    section: _map(sections['campaigns']),
                  ),
                  _HealthChip(
                    label: 'Métricas Google Ads',
                    section: _map(sections['metrics']),
                  ),
                  _HealthChip(
                    label: 'Retorno de conversões',
                    section: _map(sections['googleConversionReturn']),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Dependências',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: <Widget>[
                  _DependencyBadge(
                    label: 'IA',
                    ready: dependencies['aiRuntime'] == true,
                  ),
                  _DependencyBadge(
                    label: 'Follow-ups IA',
                    ready: dependencies['followupAiRuntime'] == true,
                  ),
                  _DependencyBadge(
                    label: 'Google Ads',
                    ready: dependencies['googleAds'] == true,
                  ),
                  _DependencyBadge(
                    label: 'Retorno Google',
                    ready: dependencies['googleDataManager'] == true,
                  ),
                  _DependencyBadge(
                    label: 'Publicação de anúncios',
                    ready: dependencies['adsPublisher'] == true,
                  ),
                  _DependencyBadge(
                    label: 'WhatsApp oficial',
                    ready: dependencies['whatsappMeta'] == true,
                  ),
                  _DependencyBadge(
                    label: 'WhatsApp QR',
                    ready: dependencies['whatsappQr'] == true,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Map<String, dynamic> _map(dynamic value) {
    return value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
  }
}

class _HealthChip extends StatelessWidget {
  const _HealthChip({required this.label, required this.section});

  final String label;
  final Map<String, dynamic> section;

  @override
  Widget build(BuildContext context) {
    final level = section['level']?.toString() ?? 'ok';
    final icon = switch (level) {
      'attention' => Icons.warning_amber_rounded,
      'processing' => Icons.hourglass_top_rounded,
      _ => Icons.check_circle_outline_rounded,
    };
    final status = switch (level) {
      'attention' => 'Atenção',
      'processing' => 'Processando',
      _ => 'Saudável',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text('$label · $status'),
        ],
      ),
    );
  }
}

class _DependencyBadge extends StatelessWidget {
  const _DependencyBadge({required this.label, required this.ready});

  final String label;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        ready ? Icons.check_rounded : Icons.info_outline_rounded,
        size: 17,
      ),
      label: Text('$label · ${ready ? 'Pronto' : 'Configuração necessária'}'),
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
