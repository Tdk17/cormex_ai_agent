import 'dart:async';

import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:agente_vendas_saas/Src/Core/di/service_locator.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/acquisition/domain/acquisition_contracts.dart';
import 'package:agente_vendas_saas/Src/Features/acquisition/presentation/controllers/acquisition_controller.dart';
import 'package:agente_vendas_saas/Src/Features/acquisition/presentation/widgets/acquisition_status_badge.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:agente_vendas_saas/Src/Shared/components/form_error_banner.dart';
import 'package:agente_vendas_saas/Src/Shared/models/acquisition_models.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:signals/signals_flutter.dart';

class AcquisitionPage extends SignalStatefulWidget {
  const AcquisitionPage({super.key});

  @override
  State<AcquisitionPage> createState() => _AcquisitionPageState();
}

class _AcquisitionPageState extends State<AcquisitionPage> {
  late final AcquisitionController controller;

  @override
  void initState() {
    super.initState();
    controller = sl<AcquisitionController>();
    if (controller.state.value == ScreenState.initial) {
      controller.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = controller.state.value;
    final workspace = sl<AuthController>().session.value?.selectedWorkspace;
    final campaigns = controller.campaigns.value;

    return RefreshIndicator(
      onRefresh: () => controller.load(force: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 44),
        children: <Widget>[
          _AcquisitionHeader(
            workspaceName: workspace?.name ?? 'sua empresa',
            onCreate: () => context.go('/acquisition/new'),
          ),
          const SizedBox(height: 20),
          _AccountStrip(
            accounts: controller.accounts.value,
            onManage: () => context.go('/integrations'),
          ),
          const SizedBox(height: 18),
          if (controller.metrics.value case final metrics?)
            _MetricsGrid(metrics: metrics),
          const SizedBox(height: 18),
          _Filters(controller: controller),
          if (controller.errorMessage.value != null &&
              (campaigns.isNotEmpty || state != ScreenState.error)) ...<Widget>[
            const SizedBox(height: 12),
            FormErrorBanner(
              message: controller.errorMessage.value!,
              correlationId: controller.correlationId.value,
            ),
          ],
          if (controller.actionMessage.value != null) ...<Widget>[
            const SizedBox(height: 12),
            _SuccessBanner(message: controller.actionMessage.value!),
          ],
          const SizedBox(height: 16),
          if (state == ScreenState.loading && campaigns.isEmpty)
            const _LoadingCentral()
          else if (state == ScreenState.error && campaigns.isEmpty)
            _CentralError(
              message: controller.errorMessage.value ??
                  'Não foi possível carregar a Central de Aquisição.',
              correlationId: controller.correlationId.value,
              onRetry: () => controller.load(force: true),
            )
          else if (campaigns.isEmpty)
            _EmptyCampaigns(onCreate: () => context.go('/acquisition/new'))
          else ...<Widget>[
            if (state == ScreenState.loading)
              const LinearProgressIndicator(minHeight: 2),
            _CampaignList(
              campaigns: campaigns,
              mutatingIds: controller.mutatingIds.value,
              onOpen: (AcquisitionCampaignModel item) =>
                  context.go('/acquisition/${item.id}'),
              onEdit: (AcquisitionCampaignModel item) =>
                  context.go('/acquisition/${item.id}/edit'),
              onAction: _handleAction,
            ),
            if (controller.nextCursor.value != null) ...<Widget>[
              const SizedBox(height: 16),
              Center(
                child: OutlinedButton.icon(
                  onPressed: controller.isLoadingMore.value
                      ? null
                      : () => controller.load(append: true),
                  icon: controller.isLoadingMore.value
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.expand_more_rounded),
                  label: const Text('Carregar mais campanhas'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _handleAction(
    AcquisitionCampaignModel campaign,
    String action,
  ) async {
    controller.clearFeedback();
    if (action == AcquisitionCampaignAction.finish) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: const Text('Encerrar campanha?'),
          content: const Text(
            'A campanha será encerrada nos provedores e não poderá ser retomada.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Encerrar'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    unawaited(controller.performAction(campaign, action));
  }
}

class _AcquisitionHeader extends StatelessWidget {
  const _AcquisitionHeader({
    required this.workspaceName,
    required this.onCreate,
  });

  final String workspaceName;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 14,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'NOVA CENTRAL',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Central de Aquisição',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 5),
              Text(
                'Crie, publique e acompanhe campanhas de $workspaceName em uma jornada conectada a Leads, Conversas e Pipeline.',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nova campanha'),
        ),
      ],
    );
  }
}

class _AccountStrip extends StatelessWidget {
  const _AccountStrip({required this.accounts, required this.onManage});

  final List<AcquisitionAdAccountModel> accounts;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    AcquisitionAdAccountModel? accountFor(String provider) {
      for (final item in accounts) {
        if (item.provider.toLowerCase() == provider) return item;
      }
      return null;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 14,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: <Widget>[
                _ProviderStatus(
                  provider: 'Google Ads',
                  icon: Icons.ads_click_rounded,
                  account: accountFor('google'),
                ),
                _ProviderStatus(
                  provider: 'Meta Ads',
                  icon: Icons.campaign_outlined,
                  account: accountFor('meta'),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: onManage,
              icon: const Icon(Icons.link_rounded),
              label: const Text('Gerenciar contas'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderStatus extends StatelessWidget {
  const _ProviderStatus({
    required this.provider,
    required this.icon,
    required this.account,
  });

  final String provider;
  final IconData icon;
  final AcquisitionAdAccountModel? account;

  @override
  Widget build(BuildContext context) {
    final connected = account?.isConnected ?? false;
    final attention = account?.requiresAttention ?? false;
    final color = attention
        ? AppColors.danger
        : connected
            ? AppColors.accent
            : AppColors.textSecondary;
    final label = attention
        ? 'Requer atenção'
        : connected
            ? account!.name
            : 'Não conectado';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 9),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(provider, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.metrics});

  final AcquisitionMetricsModel metrics;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final items = <({String label, String value, IconData icon, Color color})>[
      (
        label: 'Campanhas ativas',
        value: metrics.activeCampaigns.toString(),
        icon: Icons.rocket_launch_outlined,
        color: AppColors.primary,
      ),
      (
        label: 'Investimento',
        value: currency.format(metrics.investment),
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.blue,
      ),
      (
        label: 'Leads gerados',
        value: metrics.leads.toString(),
        icon: Icons.person_add_alt_1_outlined,
        color: AppColors.accent,
      ),
      (
        label: 'Custo por lead',
        value: currency.format(metrics.costPerLead),
        icon: Icons.price_check_outlined,
        color: AppColors.warning,
      ),
      (
        label: 'Conversões',
        value: metrics.conversions.toString(),
        icon: Icons.check_circle_outline_rounded,
        color: AppColors.primaryDark,
      ),
      (
        label: 'ROAS',
        value: '${metrics.roas.toStringAsFixed(2).replaceAll('.', ',')}x',
        icon: Icons.trending_up_rounded,
        color: AppColors.accent,
      ),
    ];
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final columns = constraints.maxWidth >= 1180
            ? 6
            : constraints.maxWidth >= 780
                ? 3
                : constraints.maxWidth >= 520
                    ? 2
                    : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items
              .map(
                (item) => SizedBox(
                  width: width,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(item.icon, color: item.color, size: 22),
                          const SizedBox(height: 13),
                          Text(
                            item.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.label,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.controller});

  final AcquisitionController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            SegmentedButton<String>(
              segments: const <ButtonSegment<String>>[
                ButtonSegment<String>(value: '7d', label: Text('7 dias')),
                ButtonSegment<String>(value: '30d', label: Text('30 dias')),
                ButtonSegment<String>(value: '90d', label: Text('90 dias')),
              ],
              selected: <String>{controller.period.value},
              showSelectedIcon: false,
              onSelectionChanged: (Set<String> value) =>
                  controller.changeFilters(
                periodValue: value.first,
                channelValue: controller.channel.value,
                statusValue: controller.status.value,
              ),
            ),
            SizedBox(
              width: 190,
              child: DropdownButtonFormField<String?>(
                initialValue: controller.channel.value,
                decoration: const InputDecoration(
                  labelText: 'Canal',
                  prefixIcon: Icon(Icons.cell_tower_rounded),
                ),
                items: const <DropdownMenuItem<String?>>[
                  DropdownMenuItem<String?>(value: null, child: Text('Todos')),
                  DropdownMenuItem<String?>(value: 'google', child: Text('Google Ads')),
                  DropdownMenuItem<String?>(value: 'meta', child: Text('Meta Ads')),
                ],
                onChanged: (String? value) => controller.changeFilters(
                  periodValue: controller.period.value,
                  channelValue: value,
                  statusValue: controller.status.value,
                ),
              ),
            ),
            SizedBox(
              width: 210,
              child: DropdownButtonFormField<String?>(
                initialValue: controller.status.value,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.filter_alt_outlined),
                ),
                items: const <DropdownMenuItem<String?>>[
                  DropdownMenuItem<String?>(value: null, child: Text('Todos')),
                  DropdownMenuItem<String?>(value: 'draft', child: Text('Rascunho')),
                  DropdownMenuItem<String?>(value: 'review', child: Text('Em revisão')),
                  DropdownMenuItem<String?>(value: 'active', child: Text('Ativa')),
                  DropdownMenuItem<String?>(value: 'paused', child: Text('Pausada')),
                  DropdownMenuItem<String?>(value: 'finished', child: Text('Encerrada')),
                ],
                onChanged: (String? value) => controller.changeFilters(
                  periodValue: controller.period.value,
                  channelValue: controller.channel.value,
                  statusValue: value,
                ),
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Atualizar',
              onPressed: () => controller.load(force: true),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampaignList extends StatelessWidget {
  const _CampaignList({
    required this.campaigns,
    required this.mutatingIds,
    required this.onOpen,
    required this.onEdit,
    required this.onAction,
  });

  final List<AcquisitionCampaignModel> campaigns;
  final Set<String> mutatingIds;
  final ValueChanged<AcquisitionCampaignModel> onOpen;
  final ValueChanged<AcquisitionCampaignModel> onEdit;
  final void Function(AcquisitionCampaignModel campaign, String action) onAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < 860) {
          return Column(
            children: campaigns
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CampaignCard(
                      campaign: item,
                      busy: mutatingIds.contains(item.id),
                      onOpen: () => onOpen(item),
                      onEdit: () => onEdit(item),
                      onAction: (String action) => onAction(item, action),
                    ),
                  ),
                )
                .toList(growable: false),
          );
        }
        return Card(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStatePropertyAll(
                  AppColors.background.withValues(alpha: 0.9),
                ),
                columns: const <DataColumn>[
                  DataColumn(label: Text('Campanha')),
                  DataColumn(label: Text('Canal')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Orçamento')),
                  DataColumn(label: Text('Leads')),
                  DataColumn(label: Text('Investimento')),
                  DataColumn(label: Text('Ações')),
                ],
                rows: campaigns
                    .map(
                      (item) => DataRow(
                        onSelectChanged: (_) => onOpen(item),
                        cells: <DataCell>[
                          DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 240),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    item.productName,
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
                          ),
                          DataCell(Text(_channelLabel(item.channels))),
                          DataCell(AcquisitionStatusBadge(status: item.status)),
                          DataCell(Text(_budget(item))),
                          DataCell(Text(item.leads.toString())),
                          DataCell(Text(_currency(item.investment))),
                          DataCell(
                            _CampaignMenu(
                              campaign: item,
                              busy: mutatingIds.contains(item.id),
                              onOpen: () => onOpen(item),
                              onEdit: () => onEdit(item),
                              onAction: (String action) => onAction(item, action),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({
    required this.campaign,
    required this.busy,
    required this.onOpen,
    required this.onEdit,
    required this.onAction,
  });

  final AcquisitionCampaignModel campaign;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                        Text(
                          campaign.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          campaign.productName,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  _CampaignMenu(
                    campaign: campaign,
                    busy: busy,
                    onOpen: onOpen,
                    onEdit: onEdit,
                    onAction: onAction,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AcquisitionStatusBadge(status: campaign.status),
              const SizedBox(height: 14),
              Wrap(
                spacing: 18,
                runSpacing: 9,
                children: <Widget>[
                  _MiniValue(label: 'Canal', value: _channelLabel(campaign.channels)),
                  _MiniValue(label: 'Orçamento', value: _budget(campaign)),
                  _MiniValue(label: 'Leads', value: campaign.leads.toString()),
                  _MiniValue(label: 'Investido', value: _currency(campaign.investment)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CampaignMenu extends StatelessWidget {
  const _CampaignMenu({
    required this.campaign,
    required this.busy,
    required this.onOpen,
    required this.onEdit,
    required this.onAction,
  });

  final AcquisitionCampaignModel campaign;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return const SizedBox.square(
        dimension: 26,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return PopupMenuButton<String>(
      tooltip: 'Ações da campanha',
      onSelected: (String value) {
        if (value == 'view') return onOpen();
        if (value == 'edit') return onEdit();
        onAction(value);
      },
      itemBuilder: (_) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'view',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.visibility_outlined),
            title: Text('Visualizar'),
          ),
        ),
        if (campaign.canEdit)
          const PopupMenuItem<String>(
            value: 'edit',
            child: ListTile(
              dense: true,
              leading: Icon(Icons.edit_outlined),
              title: Text('Editar'),
            ),
          ),
        if (campaign.canPause)
          const PopupMenuItem<String>(
            value: AcquisitionCampaignAction.pause,
            child: ListTile(
              dense: true,
              leading: Icon(Icons.pause_circle_outline_rounded),
              title: Text('Pausar'),
            ),
          ),
        if (campaign.canResume)
          const PopupMenuItem<String>(
            value: AcquisitionCampaignAction.resume,
            child: ListTile(
              dense: true,
              leading: Icon(Icons.play_circle_outline_rounded),
              title: Text('Retomar'),
            ),
          ),
        const PopupMenuItem<String>(
          value: AcquisitionCampaignAction.duplicate,
          child: ListTile(
            dense: true,
            leading: Icon(Icons.copy_all_outlined),
            title: Text('Duplicar'),
          ),
        ),
        if (campaign.canFinish)
          const PopupMenuItem<String>(
            value: AcquisitionCampaignAction.finish,
            child: ListTile(
              dense: true,
              leading: Icon(Icons.stop_circle_outlined, color: AppColors.danger),
              title: Text('Encerrar'),
            ),
          ),
      ],
      icon: const Icon(Icons.more_horiz_rounded),
    );
  }
}

class _MiniValue extends StatelessWidget {
  const _MiniValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _EmptyCampaigns extends StatelessWidget {
  const _EmptyCampaigns({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
        child: Column(
          children: <Widget>[
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.rocket_launch_outlined,
                color: AppColors.primary,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Sua próxima campanha começa aqui',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 7),
            const Text(
              'Cadastre o produto, revise as sugestões da IA e publique apenas quando tudo estiver pronto.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Criar primeira campanha'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCentral extends StatelessWidget {
  const _LoadingCentral();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 70),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _CentralError extends StatelessWidget {
  const _CentralError({
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
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Tentar novamente'),
        ),
      ],
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.check_circle_outline_rounded, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

String _channelLabel(List<String> channels) {
  if (channels.isEmpty) return '—';
  return channels
      .map((String item) => switch (item) {
            'google' => 'Google',
            'meta' => 'Meta',
            _ => item,
          })
      .join(' + ');
}

String _currency(double value) =>
    NumberFormat.simpleCurrency(locale: 'pt_BR').format(value);

String _budget(AcquisitionCampaignModel item) {
  final suffix = item.budgetType == 'daily' ? '/dia' : ' total';
  return '${_currency(item.budgetAmount)}$suffix';
}
