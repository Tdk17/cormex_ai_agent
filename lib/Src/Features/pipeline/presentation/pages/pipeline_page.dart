import 'dart:async';

import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:agente_vendas_saas/Src/Core/di/service_locator.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/pipeline/domain/pipeline_board.dart';
import 'package:agente_vendas_saas/Src/Features/pipeline/domain/pipeline_constants.dart';
import 'package:agente_vendas_saas/Src/Features/pipeline/presentation/controllers/pipeline_controller.dart';
import 'package:agente_vendas_saas/Src/Features/pipeline/presentation/widgets/opportunity_card.dart';
import 'package:agente_vendas_saas/Src/Shared/components/form_error_banner.dart';
import 'package:agente_vendas_saas/Src/Shared/models/pipeline_models.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:signals/signals_flutter.dart';

class PipelinePage extends SignalStatefulWidget {
  const PipelinePage({super.key});

  @override
  State<PipelinePage> createState() => _PipelinePageState();
}

class _PipelinePageState extends State<PipelinePage> {
  late final PipelineController controller;
  late final TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    controller = sl<PipelineController>();
    searchController = TextEditingController(text: controller.search.value);
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
    final stages = controller.stages.value;
    final summary = controller.summary.value;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final desktop = constraints.maxWidth >= 900;
        return RefreshIndicator(
          onRefresh: () => controller.load(force: true),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 40),
            children: <Widget>[
              _PipelineHeader(
                onCreate: () => context.go('/pipeline/new'),
              ),
              const SizedBox(height: 20),
              _SummaryCards(summary: summary),
              const SizedBox(height: 16),
              _PipelineFilters(
                controller: controller,
                searchController: searchController,
              ),
              if (controller.actionError.value != null) ...<Widget>[
                const SizedBox(height: 12),
                FormErrorBanner(
                  message: controller.actionError.value!,
                  correlationId: controller.correlationId.value,
                ),
              ],
              const SizedBox(height: 16),
              if (state == ScreenState.loading && stages.isEmpty)
                const _PipelineLoading()
              else if (state == ScreenState.error && stages.isEmpty)
                _PipelineError(
                  message: controller.errorMessage.value ??
                      'Não foi possível carregar o pipeline.',
                  correlationId: controller.correlationId.value,
                  onRetry: () => controller.load(force: true),
                )
              else if (stages.isNotEmpty) ...<Widget>[
                if (state == ScreenState.loading)
                  const LinearProgressIndicator(minHeight: 2),
                if (controller.opportunities.value.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _EmptyPipelineBanner(
                      onCreate: () => context.go('/pipeline/new'),
                    ),
                  ),
                if (desktop)
                  SizedBox(
                    height: 650,
                    child: _DesktopBoard(
                      controller: controller,
                      stages: stages,
                      onAction: _handleAction,
                      onDrop: _dropOpportunity,
                    ),
                  )
                else
                  _MobileBoard(
                    controller: controller,
                    stages: stages,
                    onAction: _handleAction,
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _handleAction(
    OpportunityModel opportunity,
    OpportunityCardAction action,
  ) {
    switch (action) {
      case OpportunityCardAction.view:
        context.go('/pipeline/${opportunity.id}');
        return;
      case OpportunityCardAction.edit:
        context.go('/pipeline/${opportunity.id}/edit');
        return;
      case OpportunityCardAction.move:
        unawaited(_chooseAndMove(opportunity));
        return;
    }
  }

  void _dropOpportunity(OpportunityModel opportunity, String stageId) {
    unawaited(_chooseAndMove(opportunity, initialStageId: stageId));
  }

  Future<void> _chooseAndMove(
    OpportunityModel opportunity, {
    String? initialStageId,
  }) async {
    controller.clearActionError();
    final decision = await showDialog<({String stageId, String outcome})>(
      context: context,
      builder: (BuildContext context) => _MoveOpportunityDialog(
        stages: controller.stages.value,
        initialStageId: initialStageId ?? opportunity.stageId,
        initialOutcome: opportunity.outcome,
      ),
    );
    if (decision == null) return;
    final success = await controller.moveOpportunity(
      opportunity: opportunity,
      toStageId: decision.stageId,
      outcome: decision.outcome,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Oportunidade movida com sucesso.'
              : controller.actionError.value ?? 'Não foi possível mover.',
        ),
      ),
    );
  }
}

class _PipelineHeader extends StatelessWidget {
  const _PipelineHeader({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Pipeline de Vendas', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 5),
            const Text(
              'Acompanhe e gerencie suas oportunidades',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nova oportunidade'),
        ),
      ],
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.summary});

  final PipelineSummary summary;

  @override
  Widget build(BuildContext context) {
    final cards = <_SummaryData>[
      _SummaryData(
        label: 'Leads',
        count: summary.leadsCount,
        value: summary.leadsValue,
        icon: Icons.groups_2_outlined,
        color: AppColors.blue,
      ),
      _SummaryData(
        label: 'Em negociação',
        count: summary.negotiationCount,
        value: summary.negotiationValue,
        icon: Icons.handshake_outlined,
        color: AppColors.warning,
      ),
      _SummaryData(
        label: 'Ganhos',
        count: summary.wonCount,
        value: summary.wonValue,
        icon: Icons.emoji_events_outlined,
        color: AppColors.accent,
      ),
      _SummaryData(
        label: 'Perdidos',
        count: summary.lostCount,
        value: summary.lostValue,
        icon: Icons.trending_down_rounded,
        color: AppColors.danger,
      ),
    ];
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final columns = constraints.maxWidth >= 1050
            ? 4
            : constraints.maxWidth >= 580
                ? 2
                : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map((data) => SizedBox(width: width, child: _SummaryCard(data: data)))
              .toList(growable: false),
        );
      },
    );
  }
}

class _SummaryData {
  const _SummaryData({
    required this.label,
    required this.count,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int count;
  final double value;
  final IconData icon;
  final Color color;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final _SummaryData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(data.icon, color: data.color, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(data.label, style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(
                    '${data.count} • ${NumberFormat.compactCurrency(locale: 'pt_BR', symbol: r'R$').format(data.value)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PipelineFilters extends StatelessWidget {
  const _PipelineFilters({
    required this.controller,
    required this.searchController,
  });

  final PipelineController controller;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final search = TextField(
              controller: searchController,
              onChanged: (String value) => controller.search.value = value,
              decoration: const InputDecoration(
                hintText: 'Buscar empresa, contato, produto ou oportunidade',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            );
            final owner = DropdownButtonFormField<String?>(
              initialValue: controller.ownerId.value,
              decoration: const InputDecoration(
                labelText: 'Responsável',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              items: <DropdownMenuItem<String?>>[
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Todos os responsáveis'),
                ),
                ...controller.owners.map(
                  (item) => DropdownMenuItem<String?>(
                    value: item.id,
                    child: Text(item.name),
                  ),
                ),
              ],
              onChanged: (String? value) => controller.ownerId.value = value,
            );
            if (constraints.maxWidth < 680) {
              return Column(
                children: <Widget>[
                  search,
                  const SizedBox(height: 10),
                  owner,
                ],
              );
            }
            return Row(
              children: <Widget>[
                Expanded(flex: 3, child: search),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: owner),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DesktopBoard extends StatelessWidget {
  const _DesktopBoard({
    required this.controller,
    required this.stages,
    required this.onAction,
    required this.onDrop,
  });

  final PipelineController controller;
  final List<PipelineStageModel> stages;
  final void Function(OpportunityModel, OpportunityCardAction) onAction;
  final void Function(OpportunityModel, String) onDrop;

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: stages.map((PipelineStageModel stage) {
            final items = controller.opportunitiesFor(stage.id);
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 310,
                child: DragTarget<OpportunityModel>(
                  onWillAccept: (OpportunityModel? item) =>
                      item != null &&
                      item.stageId != stage.id &&
                      !controller.movingIds.value.contains(item.id),
                  onAccept: (OpportunityModel item) => onDrop(item, stage.id),
                  builder: (
                    BuildContext context,
                    List<OpportunityModel?> candidates,
                    List<dynamic> rejected,
                  ) {
                    return _KanbanColumn(
                      stage: stage,
                      opportunities: items,
                      highlighted: candidates.isNotEmpty,
                      movingIds: controller.movingIds.value,
                      onAction: onAction,
                    );
                  },
                ),
              ),
            );
          }).toList(growable: false),
        ),
      ),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  const _KanbanColumn({
    required this.stage,
    required this.opportunities,
    required this.highlighted,
    required this.movingIds,
    required this.onAction,
  });

  final PipelineStageModel stage;
  final List<OpportunityModel> opportunities;
  final bool highlighted;
  final Set<String> movingIds;
  final void Function(OpportunityModel, OpportunityCardAction) onAction;

  @override
  Widget build(BuildContext context) {
    final color = _stageColor(stage.color);
    final total = opportunities.fold<double>(
      0,
      (double value, OpportunityModel item) => value + item.value,
    );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: highlighted
            ? color.withValues(alpha: 0.11)
            : AppColors.border.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted ? color : AppColors.border,
          width: highlighted ? 2 : 1,
        ),
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 11),
            child: Row(
              children: <Widget>[
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(stage.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    opportunities.length.toString(),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
              child: Text(
                NumberFormat.compactCurrency(locale: 'pt_BR', symbol: r'R$').format(total),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ),
          ),
          Expanded(
            child: opportunities.isEmpty
                ? const _EmptyColumn()
                : ListView.separated(
                    itemCount: opportunities.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 9),
                    itemBuilder: (BuildContext context, int index) {
                      final opportunity = opportunities[index];
                      final card = OpportunityCard(
                        opportunity: opportunity,
                        moving: movingIds.contains(opportunity.id),
                        onAction: (OpportunityCardAction action) =>
                            onAction(opportunity, action),
                      );
                      return Draggable<OpportunityModel>(
                        data: opportunity,
                        maxSimultaneousDrags:
                            movingIds.contains(opportunity.id) ? 0 : 1,
                        feedback: Material(
                          color: Colors.transparent,
                          elevation: 10,
                          child: SizedBox(width: 290, child: card),
                        ),
                        childWhenDragging: Opacity(opacity: 0.35, child: card),
                        child: card,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MobileBoard extends StatelessWidget {
  const _MobileBoard({
    required this.controller,
    required this.stages,
    required this.onAction,
  });

  final PipelineController controller;
  final List<PipelineStageModel> stages;
  final void Function(OpportunityModel, OpportunityCardAction) onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: stages.map((PipelineStageModel stage) {
        final items = controller.opportunitiesFor(stage.id);
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ExpansionTile(
            initiallyExpanded: stage.position < 2,
            maintainState: true,
            leading: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _stageColor(stage.color),
                shape: BoxShape.circle,
              ),
            ),
            title: Text(stage.name, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text('${items.length} oportunidade${items.length == 1 ? '' : 's'}'),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            children: items.isEmpty
                ? const <Widget>[_EmptyColumn(mobile: true)]
                : items
                    .map(
                      (OpportunityModel opportunity) => Padding(
                        padding: const EdgeInsets.only(top: 9),
                        child: OpportunityCard(
                          opportunity: opportunity,
                          compact: true,
                          moving: controller.movingIds.value.contains(opportunity.id),
                          onAction: (OpportunityCardAction action) =>
                              onAction(opportunity, action),
                        ),
                      ),
                    )
                    .toList(growable: false),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _MoveOpportunityDialog extends StatefulWidget {
  const _MoveOpportunityDialog({
    required this.stages,
    required this.initialStageId,
    required this.initialOutcome,
  });

  final List<PipelineStageModel> stages;
  final String initialStageId;
  final String initialOutcome;

  @override
  State<_MoveOpportunityDialog> createState() => _MoveOpportunityDialogState();
}

class _MoveOpportunityDialogState extends State<_MoveOpportunityDialog> {
  late String stageId;
  late String outcome;

  @override
  void initState() {
    super.initState();
    stageId = widget.initialStageId;
    outcome = widget.initialOutcome;
    if (stageId != PipelineStageIds.closed) outcome = OpportunityOutcomes.open;
    if (stageId == PipelineStageIds.closed && outcome == OpportunityOutcomes.open) {
      outcome = OpportunityOutcomes.won;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mover oportunidade'),
      content: SizedBox(
        width: 410,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            DropdownButtonFormField<String>(
              initialValue: stageId,
              decoration: const InputDecoration(labelText: 'Nova etapa'),
              items: widget.stages
                  .map(
                    (PipelineStageModel stage) => DropdownMenuItem<String>(
                      value: stage.id,
                      child: Text(stage.name),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (String? value) {
                if (value == null) return;
                setState(() {
                  stageId = value;
                  outcome = stageId == PipelineStageIds.closed
                      ? OpportunityOutcomes.won
                      : OpportunityOutcomes.open;
                });
              },
            ),
            if (stageId == PipelineStageIds.closed) ...<Widget>[
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const <ButtonSegment<String>>[
                  ButtonSegment<String>(
                    value: OpportunityOutcomes.won,
                    label: Text('Ganho'),
                    icon: Icon(Icons.emoji_events_outlined),
                  ),
                  ButtonSegment<String>(
                    value: OpportunityOutcomes.lost,
                    label: Text('Perdido'),
                    icon: Icon(Icons.trending_down_rounded),
                  ),
                ],
                selected: <String>{outcome},
                onSelectionChanged: (Set<String> values) {
                  setState(() => outcome = values.first);
                },
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            (stageId: stageId, outcome: outcome),
          ),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}

class _EmptyColumn extends StatelessWidget {
  const _EmptyColumn({this.mobile = false});

  final bool mobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: mobile ? 90 : 140),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(18),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.inbox_outlined, color: AppColors.textSecondary),
          SizedBox(height: 7),
          Text(
            'Nenhuma oportunidade',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PipelineLoading extends StatelessWidget {
  const _PipelineLoading();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _PipelineError extends StatelessWidget {
  const _PipelineError({
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

class _EmptyPipelineBanner extends StatelessWidget {
  const _EmptyPipelineBanner({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: <Widget>[
            const Icon(Icons.view_kanban_outlined, color: AppColors.primary),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('O pipeline está vazio. Crie a primeira oportunidade.'),
            ),
            TextButton(onPressed: onCreate, child: const Text('Criar agora')),
          ],
        ),
      ),
    );
  }
}

Color _stageColor(String value) {
  final normalized = value.replaceFirst('#', '');
  final parsed = int.tryParse(
    normalized.length == 6 ? 'FF$normalized' : normalized,
    radix: 16,
  );
  return parsed == null ? AppColors.primary : Color(parsed);
}
