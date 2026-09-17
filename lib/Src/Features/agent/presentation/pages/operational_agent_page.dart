import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:agente_vendas_saas/Src/Core/api/api_result.dart';
import 'package:agente_vendas_saas/Src/Core/di/service_locator.dart';
import 'package:agente_vendas_saas/Src/Core/http/endpoints.dart';
import 'package:agente_vendas_saas/Src/Core/http/http_manager.dart';
import 'package:agente_vendas_saas/Src/Features/agent/presentation/widgets/agent_page_header.dart';
import 'package:agente_vendas_saas/Src/Features/agent/presentation/widgets/operational_agent_activity_panel.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';

class OperationalAgentPage extends StatefulWidget {
  const OperationalAgentPage({super.key});

  @override
  State<OperationalAgentPage> createState() => _OperationalAgentPageState();
}

class _OperationalAgentPageState extends State<OperationalAgentPage> {
  final HttpManager _http = sl<HttpManager>();
  final AuthController _auth = sl<AuthController>();

  String _mode = 'copilot';
  bool _enabled = false;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _success;

  final Map<String, bool> _modules = <String, bool>{
    'campaigns': true,
    'leads': true,
    'pipeline': true,
    'conversations': true,
    'followups': true,
    'customers': true,
  };

  final Map<String, bool> _permissions = <String, bool>{
    'createFollowup': true,
    'prioritizeLead': true,
    'moveOpportunity': false,
    'sendMessage': false,
    'changeCampaignBudget': false,
    'pauseCampaign': false,
  };

  String? get _workspaceId => _auth.session.value?.selectedWorkspace?.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final workspaceId = _workspaceId;
    if (workspaceId == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Selecione uma empresa antes de configurar a IA operacional.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    final result = await _http.cloudFunction(
      name: Endpoints.operationalAgentGet,
      parameters: <String, dynamic>{'workspaceId': workspaceId},
    );

    if (!mounted) return;
    result.fold<void>(
      onSuccess: (Map<String, dynamic> data, ApiMeta meta) {
        final raw = data['config'];
        final config = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
        final modules = config['modules'];
        final permissions = config['permissions'];
        setState(() {
          _enabled = config['enabled'] == true;
          final mode = config['mode']?.toString();
          if (const <String>{'observer', 'advisor', 'copilot', 'autonomous'}.contains(mode)) {
            _mode = mode!;
          }
          if (modules is Map) {
            for (final key in _modules.keys) {
              final value = modules[key];
              if (value is bool) _modules[key] = value;
            }
          }
          if (permissions is Map) {
            for (final key in _permissions.keys) {
              final value = permissions[key];
              if (value is bool) _permissions[key] = value;
            }
          }
          _loading = false;
        });
      },
      onFailure: (error) {
        setState(() {
          _loading = false;
          _error = error.userMessage;
        });
      },
    );
  }

  Future<void> _save({bool? enabled}) async {
    if (_saving) return;
    final workspaceId = _workspaceId;
    if (workspaceId == null) {
      setState(() => _error = 'Selecione uma empresa antes de salvar.');
      return;
    }

    final nextEnabled = enabled ?? _enabled;
    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });

    final result = await _http.cloudFunction(
      name: Endpoints.operationalAgentUpdate,
      parameters: <String, dynamic>{
        'workspaceId': workspaceId,
        'config': <String, dynamic>{
          'enabled': nextEnabled,
          'mode': _mode,
          'modules': Map<String, bool>.from(_modules),
          'permissions': Map<String, bool>.from(_permissions),
        },
      },
    );

    if (!mounted) return;
    result.fold<void>(
      onSuccess: (Map<String, dynamic> data, ApiMeta meta) {
        setState(() {
          _enabled = nextEnabled;
          _saving = false;
          _success = nextEnabled
              ? 'IA operacional salva e ativada.'
              : 'Configuração da IA operacional salva.';
        });
      },
      onFailure: (error) {
        setState(() {
          _saving = false;
          _error = error.userMessage;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        AgentPageHeader(
          activeSection: 'operations',
          isActive: _enabled,
          agentName: 'Cormex AI Operacional',
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 48),
                  children: <Widget>[
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            _HeroCard(enabled: _enabled),
                            if (_error != null) ...<Widget>[
                              const SizedBox(height: 14),
                              _FeedbackBanner(message: _error!, error: true),
                            ],
                            if (_success != null) ...<Widget>[
                              const SizedBox(height: 14),
                              _FeedbackBanner(message: _success!, error: false),
                            ],
                            const SizedBox(height: 16),
                            _AutonomyCard(
                              enabled: _enabled,
                              mode: _mode,
                              busy: _saving,
                              onEnabledChanged: (bool value) => setState(() => _enabled = value),
                              onModeChanged: (String value) => setState(() => _mode = value),
                            ),
                            const SizedBox(height: 16),
                            LayoutBuilder(
                              builder: (BuildContext context, BoxConstraints constraints) {
                                final modules = _ToggleCard(
                                  title: 'O que a IA monitora',
                                  description: 'Escolha os módulos usados no monitoramento operacional.',
                                  icon: Icons.radar_outlined,
                                  labels: const <String, String>{
                                    'campaigns': 'Campanhas e mídia paga',
                                    'leads': 'Leads e qualificação',
                                    'pipeline': 'Pipeline e oportunidades',
                                    'conversations': 'Conversas e intenção',
                                    'followups': 'Follow-ups e SLA',
                                    'customers': 'Clientes e contas',
                                  },
                                  values: _modules,
                                  enabled: !_saving,
                                  onChanged: (String key, bool value) => setState(() => _modules[key] = value),
                                );
                                final permissions = _ToggleCard(
                                  title: 'Permissões de execução',
                                  description: 'Limites explícitos do que a IA pode executar.',
                                  icon: Icons.admin_panel_settings_outlined,
                                  labels: const <String, String>{
                                    'createFollowup': 'Criar follow-ups',
                                    'prioritizeLead': 'Priorizar leads',
                                    'moveOpportunity': 'Mover oportunidades',
                                    'sendMessage': 'Enviar mensagens',
                                    'changeCampaignBudget': 'Alterar orçamento de campanha',
                                    'pauseCampaign': 'Pausar campanhas',
                                  },
                                  values: _permissions,
                                  enabled: !_saving,
                                  onChanged: (String key, bool value) => setState(() => _permissions[key] = value),
                                );
                                if (constraints.maxWidth < 840) {
                                  return Column(children: <Widget>[modules, const SizedBox(height: 16), permissions]);
                                }
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Expanded(child: modules),
                                    const SizedBox(width: 16),
                                    Expanded(child: permissions),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 22),
                            OperationalAgentActivityPanel(
                              workspaceId: _workspaceId,
                              enabled: _enabled,
                            ),
                            const SizedBox(height: 18),
                            _FooterActions(
                              enabled: _enabled,
                              saving: _saving,
                              canSave: _workspaceId != null,
                              onSave: () => _save(),
                              onStop: _enabled ? () => _save(enabled: false) : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.enabled});
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF071A2E), Color(0xFF0B6B61)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: <Widget>[
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'CENTRAL DE OPERAÇÕES AUTÔNOMAS',
                  style: TextStyle(color: AppColors.shellCyan, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.1),
                ),
                SizedBox(height: 8),
                Text(
                  'Um agente trabalhando enquanto sua equipe vende.',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 8),
                Text(
                  'Monitora campanhas, leads, pipeline, conversas e follow-ups e respeita os limites definidos pela empresa.',
                  style: TextStyle(color: Colors.white70, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Chip(
            avatar: Icon(enabled ? Icons.check_circle : Icons.pause_circle_outline, size: 18),
            label: Text(enabled ? 'Ativada' : 'Desativada'),
          ),
        ],
      ),
    );
  }
}

class _AutonomyCard extends StatelessWidget {
  const _AutonomyCard({
    required this.enabled,
    required this.mode,
    required this.busy,
    required this.onEnabledChanged,
    required this.onModeChanged,
  });

  final bool enabled;
  final String mode;
  final bool busy;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<String> onModeChanged;

  @override
  Widget build(BuildContext context) {
    const modes = <String, String>{
      'observer': 'Observador',
      'advisor': 'Consultor',
      'copilot': 'Copiloto',
      'autonomous': 'Autônomo',
    };
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.account_tree_outlined, color: AppColors.primary),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Autonomia operacional', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    SizedBox(height: 3),
                    Text('Defina até onde a IA pode agir.', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Switch.adaptive(value: enabled, onChanged: busy ? null : onEnabledChanged),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: modes.entries.map((entry) {
              final selected = mode == entry.key;
              return ChoiceChip(
                selected: selected,
                label: Text(entry.value),
                onSelected: busy ? null : (_) => onModeChanged(entry.key),
              );
            }).toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  const _ToggleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.labels,
    required this.values,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final String description;
  final IconData icon;
  final Map<String, String> labels;
  final Map<String, bool> values;
  final bool enabled;
  final void Function(String key, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 3),
                    Text(description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...labels.entries.map(
            (entry) => SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(entry.value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              value: values[entry.key] ?? false,
              onChanged: enabled ? (bool value) => onChanged(entry.key, value) : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterActions extends StatelessWidget {
  const _FooterActions({
    required this.enabled,
    required this.saving,
    required this.canSave,
    required this.onSave,
    required this.onStop,
  });

  final bool enabled;
  final bool saving;
  final bool canSave;
  final VoidCallback onSave;
  final VoidCallback? onStop;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        OutlinedButton.icon(
          onPressed: saving ? null : onStop,
          icon: const Icon(Icons.stop_circle_outlined),
          label: const Text('Parar automações'),
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: saving || !canSave ? null : onSave,
          icon: saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save_outlined),
          label: Text(saving ? 'Salvando...' : enabled ? 'Salvar e ativar' : 'Salvar configuração'),
        ),
      ],
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.message, required this.error});
  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: error ? Colors.red.withValues(alpha: 0.07) : AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: error ? Colors.red.withValues(alpha: 0.22) : AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: <Widget>[
          Icon(error ? Icons.error_outline : Icons.check_circle_outline, color: error ? Colors.red : AppColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
