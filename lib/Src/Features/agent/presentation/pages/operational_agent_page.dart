import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:agente_vendas_saas/Src/Features/agent/presentation/widgets/agent_page_header.dart';
import 'package:flutter/material.dart';

class OperationalAgentPage extends StatefulWidget {
  const OperationalAgentPage({super.key});

  @override
  State<OperationalAgentPage> createState() => _OperationalAgentPageState();
}

class _OperationalAgentPageState extends State<OperationalAgentPage> {
  String _mode = 'copilot';
  bool _enabled = false;

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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 48),
            children: <Widget>[
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _HeroCard(enabled: _enabled),
                      const SizedBox(height: 16),
                      const _BackendPendingBanner(),
                      const SizedBox(height: 16),
                      const _OperationalSummary(),
                      const SizedBox(height: 16),
                      _AutonomyCard(
                        enabled: _enabled,
                        mode: _mode,
                        onEnabledChanged: (bool value) {
                          setState(() => _enabled = value);
                        },
                        onModeChanged: (String value) {
                          setState(() => _mode = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints constraints) {
                          final modules = _ModulesCard(
                            values: _modules,
                            onChanged: (String key, bool value) {
                              setState(() => _modules[key] = value);
                            },
                          );
                          final permissions = _PermissionsCard(
                            values: _permissions,
                            onChanged: (String key, bool value) {
                              setState(() => _permissions[key] = value);
                            },
                          );
                          if (constraints.maxWidth < 840) {
                            return Column(
                              children: <Widget>[
                                modules,
                                const SizedBox(height: 16),
                                permissions,
                              ],
                            );
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
                      const SizedBox(height: 16),
                      const _InsightsCard(),
                      const SizedBox(height: 16),
                      const _UsageCard(),
                      const SizedBox(height: 18),
                      _FooterActions(enabled: _enabled),
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
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'CENTRAL DE OPERAÇÕES AUTÔNOMAS',
                style: TextStyle(
                  color: AppColors.shellCyan,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Um agente trabalhando enquanto sua equipe vende.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Monitore campanhas, leads, pipeline, conversas e follow-ups em um único fluxo. A IA identifica gargalos, recomenda ações e pode executar tarefas dentro dos limites definidos pela empresa.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.76),
                  height: 1.45,
                ),
              ),
            ],
          );
          final badge = Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: enabled ? AppColors.accent : AppColors.textSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  enabled ? 'Agente ativado' : 'Agente desativado',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
          if (constraints.maxWidth < 720) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                text,
                const SizedBox(height: 16),
                Align(alignment: Alignment.centerLeft, child: badge),
              ],
            );
          }
          return Row(
            children: <Widget>[
              Expanded(child: text),
              const SizedBox(width: 24),
              badge,
            ],
          );
        },
      ),
    );
  }
}

class _BackendPendingBanner extends StatelessWidget {
  const _BackendPendingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.18)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.api_outlined, color: AppColors.blue),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Interface preparada para o Agente Operacional. Os indicadores, histórico, persistência das configurações e execução automática serão habilitados pelo contrato de API operacional.',
              style: TextStyle(color: AppColors.ink, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _OperationalSummary extends StatelessWidget {
  const _OperationalSummary();

  @override
  Widget build(BuildContext context) {
    const items = <_SummaryItem>[
      _SummaryItem('Leads analisados', Icons.groups_2_outlined),
      _SummaryItem('Oportunidades monitoradas', Icons.view_kanban_outlined),
      _SummaryItem('Campanhas monitoradas', Icons.campaign_outlined),
      _SummaryItem('Ações da IA', Icons.auto_awesome_outlined),
    ];
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 960 ? 4 : width >= 560 ? 2 : 1;
        final spacing = 12.0;
        final itemWidth = (width - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items
              .map((item) => SizedBox(width: itemWidth, child: _SummaryCard(item: item)))
              .toList(growable: false),
        );
      },
    );
  }
}

class _SummaryItem {
  const _SummaryItem(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.item});
  final _SummaryItem item;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('—', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(item.label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
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
    required this.onEnabledChanged,
    required this.onModeChanged,
  });

  final bool enabled;
  final String mode;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<String> onModeChanged;

  @override
  Widget build(BuildContext context) {
    const modes = <_ModeOption>[
      _ModeOption('observer', 'Observador', 'Monitora e registra. Não recomenda nem executa.', Icons.visibility_outlined),
      _ModeOption('advisor', 'Consultor', 'Analisa a operação e recomenda o que deve ser feito.', Icons.lightbulb_outline_rounded),
      _ModeOption('copilot', 'Copiloto', 'Prepara a ação e aguarda aprovação antes de executar.', Icons.co_present_outlined),
      _ModeOption('autonomous', 'Autônomo', 'Executa sozinho dentro dos limites e permissões definidos.', Icons.smart_toy_outlined),
    ];
    return _SectionCard(
      title: 'Autonomia operacional',
      description: 'Defina até onde a IA pode agir dentro do workspace.',
      icon: Icons.account_tree_outlined,
      trailing: Switch.adaptive(value: enabled, onChanged: onEnabledChanged),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: modes
            .map(
              (item) => SizedBox(
                width: 255,
                child: _ModeTile(
                  option: item,
                  selected: mode == item.value,
                  onTap: () => onModeChanged(item.value),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _ModeOption {
  const _ModeOption(this.value, this.title, this.description, this.icon);
  final String value;
  final String title;
  final String description;
  final IconData icon;
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({required this.option, required this.selected, required this.onTap});
  final _ModeOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary.withValues(alpha: 0.07) : AppColors.background,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(option.icon, color: selected ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(option.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(option.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.35)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModulesCard extends StatelessWidget {
  const _ModulesCard({required this.values, required this.onChanged});
  final Map<String, bool> values;
  final void Function(String key, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = <String, String>{
      'campaigns': 'Campanhas e mídia paga',
      'leads': 'Leads e qualificação',
      'pipeline': 'Pipeline e oportunidades',
      'conversations': 'Conversas e intenção',
      'followups': 'Follow-ups e SLA',
      'customers': 'Clientes e contas',
    };
    return _SectionCard(
      title: 'O que a IA monitora',
      description: 'Escolha os módulos que alimentam o agente operacional.',
      icon: Icons.radar_outlined,
      child: Column(
        children: labels.entries
            .map(
              (entry) => SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(entry.value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                value: values[entry.key] ?? false,
                onChanged: (bool value) => onChanged(entry.key, value),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _PermissionsCard extends StatelessWidget {
  const _PermissionsCard({required this.values, required this.onChanged});
  final Map<String, bool> values;
  final void Function(String key, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = <String, String>{
      'createFollowup': 'Criar follow-ups',
      'prioritizeLead': 'Priorizar leads',
      'moveOpportunity': 'Mover oportunidades',
      'sendMessage': 'Enviar mensagens',
      'changeCampaignBudget': 'Alterar orçamento de campanha',
      'pauseCampaign': 'Pausar campanhas',
    };
    return _SectionCard(
      title: 'Permissões de execução',
      description: 'A IA nunca deve ultrapassar as permissões autorizadas pelo cliente.',
      icon: Icons.admin_panel_settings_outlined,
      child: Column(
        children: labels.entries
            .map(
              (entry) => SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(entry.value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                value: values[entry.key] ?? false,
                onChanged: (bool value) => onChanged(entry.key, value),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _InsightsCard extends StatelessWidget {
  const _InsightsCard();

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      title: 'Insights e decisões',
      description: 'Alertas, recomendações e ações aprováveis aparecerão aqui.',
      icon: Icons.auto_graph_outlined,
      child: _EmptyState(
        icon: Icons.insights_outlined,
        title: 'Nenhum insight carregado',
        description: 'A API deverá retornar anomalias, recomendações, prioridade, impacto esperado e ações possíveis.',
      ),
    );
  }
}

class _UsageCard extends StatelessWidget {
  const _UsageCard();

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      title: 'Uso e custo da IA',
      description: 'Controle de consumo por workspace para permitir franquia e cobrança excedente.',
      icon: Icons.data_usage_outlined,
      child: Row(
        children: <Widget>[
          Expanded(child: _UsageMetric(label: 'Consumo no mês', value: '—')),
          SizedBox(width: 12),
          Expanded(child: _UsageMetric(label: 'Custo estimado', value: '—')),
          SizedBox(width: 12),
          Expanded(child: _UsageMetric(label: 'Ações executadas', value: '—')),
        ],
      ),
    );
  }
}

class _UsageMetric extends StatelessWidget {
  const _UsageMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _FooterActions extends StatelessWidget {
  const _FooterActions({required this.enabled});
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.stop_circle_outlined),
          label: const Text('Parar automações'),
        ),
        const Spacer(),
        Tooltip(
          message: 'Será habilitado quando a API de configuração estiver implementada.',
          child: FilledButton.icon(
            onPressed: null,
            icon: const Icon(Icons.save_outlined),
            label: Text(enabled ? 'Salvar e ativar' : 'Salvar configuração'),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final String description;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.35)),
                  ],
                ),
              ),
              if (trailing != null) ...<Widget>[const SizedBox(width: 12), trailing!],
            ],
          ),
          const SizedBox(height: 16),
          child,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.description});
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 34, color: AppColors.textSecondary),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(description, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.4)),
        ],
      ),
    );
  }
}
