import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:agente_vendas_saas/Src/Core/di/service_locator.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/leads/domain/lead_filters.dart';
import 'package:agente_vendas_saas/Src/Features/leads/domain/lead_labels.dart';
import 'package:agente_vendas_saas/Src/Features/leads/presentation/controllers/leads_controller.dart';
import 'package:agente_vendas_saas/Src/Features/leads/presentation/widgets/lead_status_badge.dart';
import 'package:agente_vendas_saas/Src/Shared/components/form_error_banner.dart';
import 'package:agente_vendas_saas/Src/Shared/models/lead_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:signals/signals_flutter.dart';

class LeadsListPage extends SignalStatefulWidget {
  const LeadsListPage({super.key});

  @override
  State<LeadsListPage> createState() => _LeadsListPageState();
}

class _LeadsListPageState extends State<LeadsListPage> {
  late final LeadsController controller;
  late final TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    controller = sl<LeadsController>();
    searchController = TextEditingController(text: controller.filters.value.search);
    if (controller.state.value == ScreenState.initial) controller.load();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = controller.state.value;
    final leads = controller.leads.value;
    final filters = controller.filters.value;

    return RefreshIndicator(
      onRefresh: () => controller.load(force: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 40),
        children: <Widget>[
          _Header(
            onCreate: () => context.go('/leads/new'),
            onImport: () => context.go('/leads/import'),
          ),
          const SizedBox(height: 22),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final search = TextField(
                    controller: searchController,
                    onChanged: controller.search,
                    decoration: const InputDecoration(
                      hintText: 'Buscar por nome, empresa, telefone, e-mail ou tag',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  );
                  final filterButton = OutlinedButton.icon(
                    onPressed: () => _openFilters(filters),
                    icon: const Icon(Icons.tune_rounded),
                    label: Text(
                      filters.activeCount == 0
                          ? 'Filtros'
                          : 'Filtros (${filters.activeCount})',
                    ),
                  );
                  if (constraints.maxWidth < 680) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        search,
                        const SizedBox(height: 10),
                        filterButton,
                      ],
                    );
                  }
                  return Row(
                    children: <Widget>[
                      Expanded(child: search),
                      const SizedBox(width: 12),
                      filterButton,
                    ],
                  );
                },
              ),
            ),
          ),
          if (filters.activeCount > 0) ...<Widget>[
            const SizedBox(height: 10),
            _ActiveFilters(filters: filters, onClear: controller.clearFilters),
          ],
          const SizedBox(height: 16),
          if (state == ScreenState.loading && leads.isEmpty)
            const _LoadingLeads()
          else if (state == ScreenState.error && leads.isEmpty)
            _ErrorState(
              message: controller.errorMessage.value ?? 'Erro ao carregar leads.',
              correlationId: controller.correlationId.value,
              onRetry: () => controller.load(force: true),
            )
          else if (leads.isEmpty)
            _EmptyLeads(
              filtered: !filters.isEmpty,
              onCreate: () => context.go('/leads/new'),
              onClear: controller.clearFilters,
            )
          else ...<Widget>[
            if (state == ScreenState.loading)
              const LinearProgressIndicator(minHeight: 2),
            if (controller.errorMessage.value != null) ...<Widget>[
              FormErrorBanner(
                message: controller.errorMessage.value!,
                correlationId: controller.correlationId.value,
              ),
              const SizedBox(height: 10),
            ],
            _LeadsContent(leads: leads),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Text(
                  '${leads.length} lead${leads.length == 1 ? '' : 's'} carregado${leads.length == 1 ? '' : 's'}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const Spacer(),
                if (controller.hasMore)
                  OutlinedButton.icon(
                    onPressed: controller.isLoadingMore.value ? null : controller.loadMore,
                    icon: controller.isLoadingMore.value
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.expand_more_rounded),
                    label: const Text('Carregar mais'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openFilters(LeadFilters current) async {
    final result = await showDialog<LeadFilters>(
      context: context,
      builder: (BuildContext context) => _FiltersDialog(initial: current),
    );
    if (result != null) await controller.applyFilters(result);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onCreate, required this.onImport});

  final VoidCallback onCreate;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 14,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Leads', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 5),
            const Text(
              'Gerencie, qualifique e acompanhe sua base comercial.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: <Widget>[
            OutlinedButton.icon(
              onPressed: onImport,
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Importar CSV'),
            ),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Novo lead'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters({required this.filters, required this.onClear});

  final LeadFilters filters;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        if (filters.status != null)
          Chip(label: Text('Status: ${LeadLabels.status(filters.status!)}')),
        if (filters.source != null)
          Chip(label: Text('Origem: ${LeadLabels.source(filters.source!)}')),
        if (filters.tag != null) Chip(label: Text('Tag: ${filters.tag}')),
        TextButton.icon(
          onPressed: onClear,
          icon: const Icon(Icons.close_rounded, size: 17),
          label: const Text('Limpar filtros'),
        ),
      ],
    );
  }
}

class _LeadsContent extends StatelessWidget {
  const _LeadsContent({required this.leads});

  final List<LeadModel> leads;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < 780) {
          return Column(
            children: leads
                .map((LeadModel lead) => _LeadCard(lead: lead))
                .toList(growable: false),
          );
        }
        return Card(
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const <DataColumn>[
                DataColumn(label: Text('Lead')),
                DataColumn(label: Text('Empresa')),
                DataColumn(label: Text('Origem')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Score'), numeric: true),
                DataColumn(label: Text('Atualizado')),
                DataColumn(label: SizedBox.shrink()),
              ],
              rows: leads.map((LeadModel lead) {
                return DataRow(
                  onSelectChanged: (_) => context.go('/leads/${lead.id}'),
                  cells: <DataCell>[
                    DataCell(
                      SizedBox(
                        width: 210,
                        child: Row(
                          children: <Widget>[
                            _LeadAvatar(name: lead.name),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    lead.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    lead.email ?? lead.phone ?? 'Sem contato',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                    ),
                    DataCell(SizedBox(width: 120, child: Text(lead.company ?? '—'))),
                    DataCell(Text(LeadLabels.source(lead.source))),
                    DataCell(LeadStatusBadge(status: lead.status)),
                    DataCell(_Score(value: lead.score)),
                    DataCell(Text(DateFormat('dd/MM/yy').format(lead.updatedAt))),
                    DataCell(
                      IconButton(
                        tooltip: 'Editar lead',
                        onPressed: () => context.go('/leads/${lead.id}/edit'),
                        icon: const Icon(Icons.edit_outlined, size: 19),
                      ),
                    ),
                  ],
                );
              }).toList(growable: false),
            ),
          ),
        );
      },
    );
  }
}

class _LeadCard extends StatelessWidget {
  const _LeadCard({required this.lead});

  final LeadModel lead;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/leads/${lead.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  _LeadAvatar(name: lead.name),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(lead.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          lead.company ?? 'Sem empresa',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  LeadStatusBadge(status: lead.status),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 14,
                runSpacing: 8,
                children: <Widget>[
                  _Meta(icon: Icons.mail_outline, text: lead.email ?? 'Sem e-mail'),
                  _Meta(icon: Icons.phone_outlined, text: lead.phone ?? 'Sem telefone'),
                  _Meta(icon: Icons.ads_click_outlined, text: LeadLabels.source(lead.source)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  _Score(value: lead.score),
                  const Spacer(),
                  Text(
                    'Atualizado em ${DateFormat('dd/MM/yy').format(lead.updatedAt)}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeadAvatar extends StatelessWidget {
  const _LeadAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 19,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      foregroundColor: AppColors.primary,
      child: Text(
        name.trim().isEmpty ? '?' : name.trim().substring(0, 1).toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Score extends StatelessWidget {
  const _Score({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final color = value >= 70
        ? AppColors.accent
        : value >= 45
            ? AppColors.warning
            : AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.bolt_rounded, size: 17, color: color),
        Text('$value', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}

class _FiltersDialog extends StatefulWidget {
  const _FiltersDialog({required this.initial});

  final LeadFilters initial;

  @override
  State<_FiltersDialog> createState() => _FiltersDialogState();
}

class _FiltersDialogState extends State<_FiltersDialog> {
  String? status;
  String? source;
  late final TextEditingController tagController;

  @override
  void initState() {
    super.initState();
    status = widget.initial.status;
    source = widget.initial.source;
    tagController = TextEditingController(text: widget.initial.tag);
  }

  @override
  void dispose() {
    tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filtrar leads'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            DropdownButtonFormField<String?>(
              initialValue: status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: <DropdownMenuItem<String?>>[
                const DropdownMenuItem<String?>(value: null, child: Text('Todos')),
                ...LeadLabels.statuses.entries.map(
                  (entry) => DropdownMenuItem<String?>(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                ),
              ],
              onChanged: (String? value) => setState(() => status = value),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String?>(
              initialValue: source,
              decoration: const InputDecoration(labelText: 'Origem'),
              items: <DropdownMenuItem<String?>>[
                const DropdownMenuItem<String?>(value: null, child: Text('Todas')),
                ...LeadLabels.sources.entries.map(
                  (entry) => DropdownMenuItem<String?>(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                ),
              ],
              onChanged: (String? value) => setState(() => source = value),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: tagController,
              decoration: const InputDecoration(
                labelText: 'Tag',
                hintText: 'Ex.: prioridade',
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(const LeadFilters()),
          child: const Text('Limpar'),
        ),
        FilledButton(
          onPressed: () {
            final tag = tagController.text.trim();
            Navigator.of(context).pop(
              LeadFilters(
                status: status,
                source: source,
                tag: tag.isEmpty ? null : tag,
              ),
            );
          },
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}

class _LoadingLeads extends StatelessWidget {
  const _LoadingLeads();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(36),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.correlationId,
    required this.onRetry,
  });

  final String message;
  final String? correlationId;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        FormErrorBanner(message: message, correlationId: correlationId),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Tentar novamente'),
        ),
      ],
    );
  }
}

class _EmptyLeads extends StatelessWidget {
  const _EmptyLeads({
    required this.filtered,
    required this.onCreate,
    required this.onClear,
  });

  final bool filtered;
  final VoidCallback onCreate;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 52),
        child: Column(
          children: <Widget>[
            const Icon(Icons.person_search_outlined, size: 48, color: AppColors.primary),
            const SizedBox(height: 14),
            Text(
              filtered ? 'Nenhum lead encontrado' : 'Sua base de leads começa aqui',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 7),
            Text(
              filtered
                  ? 'Tente mudar a busca ou remover os filtros aplicados.'
                  : 'Cadastre o primeiro contato ou importe uma planilha CSV.',
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: filtered ? onClear : onCreate,
              child: Text(filtered ? 'Limpar filtros' : 'Cadastrar lead'),
            ),
          ],
        ),
      ),
    );
  }
}
