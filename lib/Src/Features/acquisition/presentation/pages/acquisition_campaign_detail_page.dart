import 'dart:async';

import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:agente_vendas_saas/Src/Core/di/service_locator.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/acquisition/domain/acquisition_contracts.dart';
import 'package:agente_vendas_saas/Src/Features/acquisition/presentation/controllers/acquisition_campaign_detail_controller.dart';
import 'package:agente_vendas_saas/Src/Features/acquisition/presentation/controllers/acquisition_controller.dart';
import 'package:agente_vendas_saas/Src/Features/acquisition/presentation/widgets/acquisition_status_badge.dart';
import 'package:agente_vendas_saas/Src/Shared/components/form_error_banner.dart';
import 'package:agente_vendas_saas/Src/Shared/models/acquisition_models.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:signals/signals_flutter.dart';

class AcquisitionCampaignDetailPage extends SignalStatefulWidget {
  const AcquisitionCampaignDetailPage({
    super.key,
    required this.campaignId,
  });

  final String campaignId;

  @override
  State<AcquisitionCampaignDetailPage> createState() =>
      _AcquisitionCampaignDetailPageState();
}

class _AcquisitionCampaignDetailPageState
    extends State<AcquisitionCampaignDetailPage> {
  late final AcquisitionCampaignDetailController controller;

  @override
  void initState() {
    super.initState();
    controller = sl<AcquisitionCampaignDetailController>();
    unawaited(controller.load(widget.campaignId));
  }

  @override
  Widget build(BuildContext context) {
    final state = controller.state.value;
    final campaign = controller.campaign.value;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 44),
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => context.go('/acquisition'),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Voltar para a Central'),
          ),
        ),
        const SizedBox(height: 8),
        if (state == ScreenState.loading || state == ScreenState.initial)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 90),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (state == ScreenState.error || campaign == null)
          Column(
            children: <Widget>[
              FormErrorBanner(
                message: controller.errorMessage.value ??
                    'Campanha não encontrada.',
                correlationId: controller.correlationId.value,
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => controller.load(widget.campaignId),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
              ),
            ],
          )
        else
          _CampaignDetail(
            campaign: campaign,
            onEdit: () => context.go('/acquisition/${campaign.id}/edit'),
            onAction: (String action) => _performAction(campaign, action),
          ),
      ],
    );
  }

  Future<void> _performAction(
    AcquisitionCampaignModel campaign,
    String action,
  ) async {
    if (action == AcquisitionCampaignAction.finish) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: const Text('Encerrar campanha?'),
          content: const Text(
            'Essa ação interrompe a campanha nos provedores e não pode ser desfeita.',
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
    final central = sl<AcquisitionController>();
    final success = await central.performAction(campaign, action);
    if (!mounted) return;
    if (success) {
      await controller.load(widget.campaignId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            central.errorMessage.value ?? 'Não foi possível atualizar a campanha.',
          ),
        ),
      );
    }
  }
}

class _CampaignDetail extends StatelessWidget {
  const _CampaignDetail({
    required this.campaign,
    required this.onEdit,
    required this.onAction,
  });

  final AcquisitionCampaignModel campaign;
  final VoidCallback onEdit;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _Header(campaign: campaign, onEdit: onEdit, onAction: onAction),
        const SizedBox(height: 18),
        _Performance(campaign: campaign),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final input = campaign.input ?? const <String, dynamic>{};
            final children = <Widget>[
              _DetailCard(
                title: 'Configuração comercial',
                icon: Icons.tune_rounded,
                rows: <({String label, String value})>[
                  (label: 'Produto', value: campaign.productName),
                  (label: 'Objetivo', value: _label(campaign.objective)),
                  (label: 'Canais', value: campaign.channels.map(_label).join(' + ')),
                  (label: 'Orçamento', value: '${_money(campaign.budgetAmount)} ${campaign.budgetType == 'daily' ? 'por dia' : 'total'}'),
                  (label: 'Início', value: _date(campaign.startAt)),
                  (label: 'Término', value: campaign.endAt == null ? 'Execução contínua' : _date(campaign.endAt)),
                ],
              ),
              _DetailCard(
                title: 'Criativo e destino',
                icon: Icons.auto_awesome_outlined,
                rows: _creativeRows(input),
              ),
              _DetailCard(
                title: 'Automação pós-lead',
                icon: Icons.smart_toy_outlined,
                rows: _automationRows(input),
              ),
              _DetailCard(
                title: 'Rastreamento',
                icon: Icons.hub_outlined,
                rows: <({String label, String value})>[
                  (label: 'ID CormeX', value: campaign.id),
                  (label: 'Versão', value: campaign.version.toString()),
                  (label: 'Atualização', value: _dateTime(campaign.updatedAt)),
                  ...campaign.providerCampaignIds.entries.map(
                    (entry) => (label: _label(entry.key), value: entry.value),
                  ),
                ],
              ),
            ];
            if (constraints.maxWidth < 900) {
              return Column(
                children: children
                    .expand((Widget item) => <Widget>[item, const SizedBox(height: 14)])
                    .toList(growable: false),
              );
            }
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: children
                  .map(
                    (Widget item) => SizedBox(
                      width: (constraints.maxWidth - 14) / 2,
                      child: item,
                    ),
                  )
                  .toList(growable: false),
            );
          },
        ),
        const SizedBox(height: 18),
        const _FinancialNotice(),
      ],
    );
  }

  static List<({String label, String value})> _creativeRows(
    Map<String, dynamic> input,
  ) {
    final creative = _map(input['creative']);
    final destination = _map(input['destination']);
    return <({String label, String value})>[
      (label: 'Título', value: _text(creative['headline'])),
      (label: 'Texto principal', value: _text(creative['primaryText'])),
      (label: 'Descrição', value: _text(creative['description'])),
      (label: 'Chamada', value: _label(_text(creative['callToAction']))),
      (label: 'Destino', value: _label(_text(destination['type']))),
      (label: 'URL', value: _text(destination['url'])),
    ];
  }

  static List<({String label, String value})> _automationRows(
    Map<String, dynamic> input,
  ) {
    final automation = _map(input['automation']);
    final questions = automation['qualificationQuestions'];
    final tags = automation['tags'];
    return <({String label, String value})>[
      (
        label: 'Modo',
        value: automation['onlyRegisterLead'] == true
            ? 'Apenas registrar lead'
            : 'Iniciar atendimento',
      ),
      (label: 'Mensagem inicial', value: _text(automation['initialMessage'])),
      (
        label: 'Perguntas',
        value: questions is List
            ? questions.map((dynamic item) => item.toString()).join(' • ')
            : '—',
      ),
      (label: 'Etapa do Pipeline', value: _label(_text(automation['pipelineStageId']))),
      (
        label: 'Tags',
        value: tags is List
            ? tags.map((dynamic item) => item.toString()).join(', ')
            : '—',
      ),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.campaign,
    required this.onEdit,
    required this.onAction,
  });

  final AcquisitionCampaignModel campaign;
  final VoidCallback onEdit;
  final ValueChanged<String> onAction;

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
            AcquisitionStatusBadge(status: campaign.status),
            const SizedBox(height: 9),
            Text(campaign.name, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              campaign.productName,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: <Widget>[
            if (campaign.canEdit)
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar'),
              ),
            if (campaign.canPause)
              OutlinedButton.icon(
                onPressed: () => onAction(AcquisitionCampaignAction.pause),
                icon: const Icon(Icons.pause_rounded),
                label: const Text('Pausar'),
              ),
            if (campaign.canResume)
              FilledButton.icon(
                onPressed: () => onAction(AcquisitionCampaignAction.resume),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Retomar'),
              ),
            PopupMenuButton<String>(
              tooltip: 'Mais ações',
              onSelected: onAction,
              itemBuilder: (_) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: AcquisitionCampaignAction.duplicate,
                  child: Text('Duplicar como rascunho'),
                ),
                if (campaign.canFinish)
                  const PopupMenuItem<String>(
                    value: AcquisitionCampaignAction.finish,
                    child: Text('Encerrar campanha'),
                  ),
              ],
              icon: const Icon(Icons.more_vert_rounded),
            ),
          ],
        ),
      ],
    );
  }
}

class _Performance extends StatelessWidget {
  const _Performance({required this.campaign});

  final AcquisitionCampaignModel campaign;

  @override
  Widget build(BuildContext context) {
    final costPerLead = campaign.leads == 0
        ? 0.0
        : campaign.investment / campaign.leads;
    final items = <({String label, String value, IconData icon})>[
      (label: 'Investimento', value: _money(campaign.investment), icon: Icons.payments_outlined),
      (label: 'Leads gerados', value: campaign.leads.toString(), icon: Icons.person_add_alt_1_outlined),
      (label: 'Custo por lead', value: _money(costPerLead), icon: Icons.price_check_outlined),
      (label: 'Conversões', value: campaign.conversions.toString(), icon: Icons.check_circle_outline_rounded),
    ];
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
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
                      padding: const EdgeInsets.all(17),
                      child: Row(
                        children: <Widget>[
                          Icon(item.icon, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(item.value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                                Text(item.label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ],
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

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.title, required this.icon, required this.rows});

  final String title;
  final IconData icon;
  final List<({String label, String value})> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, color: AppColors.primary, size: 21),
                const SizedBox(width: 9),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 16),
            ...rows.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 122,
                      child: Text(item.label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ),
                    Expanded(
                      child: Text(
                        item.value.trim().isEmpty ? '—' : item.value,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinancialNotice extends StatelessWidget {
  const _FinancialNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.18)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.account_balance_outlined, color: AppColors.blue),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'O investimento exibido pertence às contas do anunciante. Google e Meta cobram diretamente; ele não integra a assinatura do CormeX.',
            ),
          ),
        ],
      ),
    );
  }
}

Map<String, dynamic> _map(dynamic raw) => raw is Map
    ? Map<String, dynamic>.from(raw)
    : <String, dynamic>{};

String _text(dynamic raw) {
  final value = raw?.toString().trim() ?? '';
  return value.isEmpty ? '—' : value;
}

String _label(String value) => switch (value) {
      'google' => 'Google Ads',
      'meta' => 'Meta Ads',
      'leads' => 'Gerar leads',
      'messages' => 'Receber mensagens',
      'conversions' => 'Gerar conversões',
      'traffic' => 'Direcionar tráfego',
      'awareness' => 'Divulgar oferta',
      'whatsapp' => 'Conversa / WhatsApp',
      'landing_page' => 'Landing page',
      'form' => 'Formulário de lead',
      'product_page' => 'Página do produto',
      'LEARN_MORE' => 'Saiba mais',
      'CONTACT_US' => 'Fale conosco',
      'SIGN_UP' => 'Cadastre-se',
      'SHOP_NOW' => 'Comprar agora',
      'SEND_MESSAGE' => 'Enviar mensagem',
      'new_lead' => 'Novo lead',
      'contacted' => 'Contato feito',
      'proposal' => 'Proposta enviada',
      _ => value.isEmpty ? '—' : value,
    };

String _money(double value) =>
    NumberFormat.simpleCurrency(locale: 'pt_BR').format(value);

String _date(DateTime? value) => value == null
    ? '—'
    : DateFormat('dd/MM/yyyy').format(value.toLocal());

String _dateTime(DateTime value) =>
    DateFormat('dd/MM/yyyy HH:mm').format(value.toLocal());
