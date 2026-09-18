import 'dart:async';

import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:agente_vendas_saas/Src/Core/api/api_result.dart';
import 'package:agente_vendas_saas/Src/Core/di/service_locator.dart';
import 'package:agente_vendas_saas/Src/Core/http/endpoints.dart';
import 'package:agente_vendas_saas/Src/Core/http/http_manager.dart';
import 'package:flutter/material.dart';

class OperationalAgentActivityPanel extends StatefulWidget {
  const OperationalAgentActivityPanel({
    required this.workspaceId,
    required this.enabled,
    super.key,
  });

  final String? workspaceId;
  final bool enabled;

  @override
  State<OperationalAgentActivityPanel> createState() => _OperationalAgentActivityPanelState();
}

class _OperationalAgentActivityPanelState extends State<OperationalAgentActivityPanel> {
  final HttpManager _http = sl<HttpManager>();
  Timer? _timer;
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  Map<String, dynamic> _activity = <String, dynamic>{};
  Map<String, dynamic> _health = <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted && widget.enabled) _load(silent: true);
    });
  }

  @override
  void didUpdateWidget(covariant OperationalAgentActivityPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workspaceId != widget.workspaceId || oldWidget.enabled != widget.enabled) {
      _load();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    final workspaceId = widget.workspaceId;
    if (workspaceId == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Selecione uma empresa para acompanhar a atividade da IA.';
      });
      return;
    }

    if (!silent) {
      setState(() {
        _loading = _activity.isEmpty;
        _refreshing = !_loading;
        _error = null;
      });
    }

    final results = await Future.wait([
      _http.cloudFunction(
        name: Endpoints.operationalAgentActivity,
        parameters: <String, dynamic>{'workspaceId': workspaceId},
      ),
      _http.cloudFunction(
        name: Endpoints.aiOperationsHealth,
        parameters: <String, dynamic>{'workspaceId': workspaceId},
      ),
    ]);

    if (!mounted) return;

    String? nextError;
    Map<String, dynamic>? activity;
    Map<String, dynamic>? health;

    results[0].fold<void>(
      onSuccess: (Map<String, dynamic> data, ApiMeta meta) => activity = data,
      onFailure: (error) => nextError = error.userMessage,
    );
    results[1].fold<void>(
      onSuccess: (Map<String, dynamic> data, ApiMeta meta) => health = data,
      onFailure: (error) => nextError ??= error.userMessage,
    );

    setState(() {
      if (activity != null) _activity = activity!;
      if (health != null) _health = health!;
      _error = nextError;
      _loading = false;
      _refreshing = false;
    });
  }

  Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  List<Map<String, dynamic>> _list(dynamic value) {
    if (value is! List) return const <Map<String, dynamic>>[];
    return value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(growable: false);
  }

  num _num(dynamic value) => value is num ? value : num.tryParse(value?.toString() ?? '') ?? 0;

  String _money(dynamic value) => 'R\$ ${_num(value).toStringAsFixed(2).replaceAll('.', ',')}';

  String _timeAgo(dynamic raw) {
    DateTime? date;
    if (raw is DateTime) date = raw;
    if (raw is String) date = DateTime.tryParse(raw);
    if (raw is Map && raw['iso'] is String) date = DateTime.tryParse(raw['iso'].toString());
    if (date == null) return 'agora';
    final diff = DateTime.now().difference(date.toLocal());
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours} h';
    return 'há ${diff.inDays} d';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final snapshot = _map(_activity['snapshot']);
    final metrics = _map(snapshot['metrics']);
    final today = _map(metrics['today']);
    final counts = _map(snapshot['counts24h']);
    final monitor = _map(_activity['monitor']);
    final events = _list(_activity['events']);
    final dependencies = _map(_health['dependencies']);
    final dependencyStates = _map(_health['dependencyStates']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Atividade da IA em tempo real', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  SizedBox(height: 4),
                  Text(
                    'Mostra o que a IA está observando, o que detectou e o que executou ou recomendou.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Atualizar agora',
              onPressed: _refreshing ? null : () => _load(),
              icon: _refreshing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh),
            ),
          ],
        ),
        if (_error != null) ...<Widget>[
          const SizedBox(height: 10),
          _Banner(message: _error!, warning: true),
        ],
        if (!widget.enabled) ...<Widget>[
          const SizedBox(height: 10),
          const _Banner(
            message: 'A IA Operacional está desativada. O painel continua mostrando o histórico já registrado.',
            warning: true,
          ),
        ],
        const SizedBox(height: 14),
        _MetricsGrid(
          impressions: _num(today['impressions']).toInt(),
          clicks: _num(today['clicks']).toInt(),
          ctr: _num(today['ctr']).toDouble(),
          conversions: _num(today['conversions']).toDouble(),
          spend: _money(today['spend']),
          leads: _num(counts['newLeads']).toInt(),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final connections = _ConnectionsCard(
              dependencies: dependencies,
              states: dependencyStates,
            );
            final monitorCard = _MonitorCard(
              lastObserved: _timeAgo(monitor['lastObservedAt']),
              eventCount: _num(monitor['eventCount']).toInt(),
              counts: counts,
            );
            if (constraints.maxWidth < 840) {
              return Column(children: <Widget>[connections, const SizedBox(height: 14), monitorCard]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: connections),
                const SizedBox(width: 14),
                Expanded(child: monitorCard),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        _ActivityTimeline(events: events, timeAgo: _timeAgo),
      ],
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({
    required this.impressions,
    required this.clicks,
    required this.ctr,
    required this.conversions,
    required this.spend,
    required this.leads,
  });

  final int impressions;
  final int clicks;
  final double ctr;
  final double conversions;
  final String spend;
  final int leads;

  @override
  Widget build(BuildContext context) {
    final items = <(String, String, IconData)>[
      ('Impressões hoje', '$impressions', Icons.visibility_outlined),
      ('Cliques hoje', '$clicks', Icons.ads_click_outlined),
      ('CTR', '${ctr.toStringAsFixed(2)}%', Icons.percent),
      ('Conversões', conversions.toStringAsFixed(conversions % 1 == 0 ? 0 : 1), Icons.track_changes_outlined),
      ('Investimento', spend, Icons.payments_outlined),
      ('Novos leads 24h', '$leads', Icons.person_add_alt_1_outlined),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1000 ? 6 : width >= 700 ? 3 : 2;
        final itemWidth = (width - ((columns - 1) * 10)) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items.map((item) => SizedBox(
            width: itemWidth,
            child: _MetricCard(label: item.$1, value: item.$2, icon: item.$3),
          )).toList(growable: false),
        );
      },
    );
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: .5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: AppColors.primary, size: 19),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _ConnectionsCard extends StatelessWidget {
  const _ConnectionsCard({
    required this.dependencies,
    required this.states,
  });
  final Map<String, dynamic> dependencies;
  final Map<String, dynamic> states;

  @override
  Widget build(BuildContext context) {
    const labels = <String, String>{
      'googleAds': 'Google Ads',
      'googleDataManager': 'Google Data Manager',
      'aiRuntime': 'Runtime da IA',
      'followupAiRuntime': 'IA de follow-up',
      'adsPublisher': 'Publicador de anúncios',
      'whatsappMeta': 'WhatsApp Meta',
      'whatsappQr': 'WhatsApp QR / Evolution',
    };
    return _Panel(
      title: 'Conexões e executores',
      subtitle: 'A IA só consegue executar ações quando o serviço correspondente está disponível.',
      child: Column(
        children: labels.entries.map((entry) {
          final state = states[entry.key] is Map
              ? Map<String, dynamic>.from(states[entry.key] as Map)
              : <String, dynamic>{};
          final operational =
              state['operational'] == true || dependencies[entry.key] == true;
          final configured = state['configured'] == true;
          final connected = state['connected'];
          final label = operational
              ? 'Operacional'
              : connected == false
                  ? 'Desconectado'
                  : configured
                      ? 'Configurado'
                      : 'Pendente';
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              operational ? Icons.check_circle : Icons.error_outline,
              color: operational ? Colors.green : Colors.orange,
            ),
            title: Text(
              entry.value,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            trailing: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: operational ? Colors.green : Colors.orange,
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

class _MonitorCard extends StatelessWidget {
  const _MonitorCard({required this.lastObserved, required this.eventCount, required this.counts});
  final String lastObserved;
  final int eventCount;
  final Map<String, dynamic> counts;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, dynamic)>[
      ('Última varredura automática', lastObserved),
      ('Eventos recentes', eventCount),
      ('Conversas movimentadas 24h', counts['conversations'] ?? 0),
      ('Follow-ups processados 24h', counts['followups'] ?? 0),
      ('Oportunidades movimentadas 24h', counts['opportunities'] ?? 0),
      ('Clientes criados 24h', counts['customers'] ?? 0),
    ];
    return _Panel(
      title: 'Monitoramento operacional',
      subtitle: 'Leituras objetivas feitas no ecossistema CormeX.',
      child: Column(
        children: rows.map((row) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: <Widget>[
              Expanded(child: Text(row.$1, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
              Text('${row.$2}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
            ],
          ),
        )).toList(growable: false),
      ),
    );
  }
}

class _ActivityTimeline extends StatelessWidget {
  const _ActivityTimeline({required this.events, required this.timeAgo});
  final List<Map<String, dynamic>> events;
  final String Function(dynamic value) timeAgo;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Linha do tempo da IA',
      subtitle: 'Observações, alertas, recomendações e ações ficam registradas aqui.',
      child: events.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Center(
                child: Text(
                  'Ainda não há eventos. Após ativar o monitor agendado no Back4App, as leituras aparecerão automaticamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          : Column(
              children: events.take(20).map((event) {
                final type = event['type']?.toString() ?? 'observation';
                final severity = event['severity']?.toString() ?? 'info';
                final icon = switch (type) {
                  'recommendation' => Icons.lightbulb_outline,
                  'action' => Icons.bolt_outlined,
                  'system' => Icons.settings_suggest_outlined,
                  _ => Icons.radar_outlined,
                };
                final color = severity == 'warning'
                    ? Colors.orange
                    : severity == 'error'
                        ? Colors.red
                        : type == 'action'
                            ? Colors.green
                            : AppColors.primary;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: .5)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: color.withValues(alpha: .12),
                          child: Icon(icon, color: color, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(child: Text(event['title']?.toString() ?? 'Atividade', style: const TextStyle(fontWeight: FontWeight.w900))),
                                  const SizedBox(width: 8),
                                  Text(timeAgo(event['occurredAt']), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                ],
                              ),
                              if ((event['description']?.toString() ?? '').isNotEmpty) ...<Widget>[
                                const SizedBox(height: 5),
                                Text(event['description'].toString(), style: const TextStyle(color: AppColors.textSecondary, height: 1.35, fontSize: 12)),
                              ],
                              const SizedBox(height: 7),
                              Text(
                                '${type == 'recommendation' ? 'RECOMENDAÇÃO' : type == 'action' ? 'AÇÃO' : type == 'system' ? 'SISTEMA' : 'OBSERVAÇÃO'} · ${(event['module']?.toString() ?? 'system').toUpperCase()}',
                                style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: .6),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.subtitle, required this.child});
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: .5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.message, required this.warning});
  final String message;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final color = warning ? Colors.orange : Colors.green;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Row(
        children: <Widget>[
          Icon(warning ? Icons.info_outline : Icons.check_circle_outline, color: color, size: 18),
          const SizedBox(width: 9),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
