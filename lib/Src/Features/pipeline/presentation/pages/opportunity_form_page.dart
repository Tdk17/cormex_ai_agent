import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:agente_vendas_saas/Src/Core/di/service_locator.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/pipeline/domain/opportunity_input.dart';
import 'package:agente_vendas_saas/Src/Features/pipeline/domain/pipeline_constants.dart';
import 'package:agente_vendas_saas/Src/Features/pipeline/presentation/controllers/opportunity_form_controller.dart';
import 'package:agente_vendas_saas/Src/Shared/components/form_error_banner.dart';
import 'package:agente_vendas_saas/Src/Shared/components/primary_loading_button.dart';
import 'package:agente_vendas_saas/Src/Shared/models/lead_model.dart';
import 'package:agente_vendas_saas/Src/Shared/models/pipeline_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:signals/signals_flutter.dart';

class OpportunityFormPage extends SignalStatefulWidget {
  const OpportunityFormPage({super.key, this.opportunityId});

  final String? opportunityId;

  @override
  State<OpportunityFormPage> createState() => _OpportunityFormPageState();
}

class _OpportunityFormPageState extends State<OpportunityFormPage> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final companyController = TextEditingController();
  final contactController = TextEditingController();
  final valueController = TextEditingController();
  final productController = TextEditingController();
  late final OpportunityFormController controller;

  String? leadId;
  String? stageId;
  String? ownerId;
  String source = 'manual';
  String outcome = OpportunityOutcomes.open;
  double probability = 20;
  DateTime? nextActivityAt;

  bool get editing => widget.opportunityId != null;

  @override
  void initState() {
    super.initState();
    controller = sl<OpportunityFormController>();
    _initialize();
  }

  Future<void> _initialize() async {
    await controller.initialize(opportunityId: widget.opportunityId);
    if (!mounted || controller.loadState.value != ScreenState.success) return;
    final current = controller.opportunity.value;
    if (current != null) {
      leadId = current.leadId;
      stageId = current.stageId;
      ownerId = current.ownerId;
      source = current.source;
      outcome = current.outcome;
      probability = current.probability.toDouble();
      nextActivityAt = current.nextActivityAt;
      titleController.text = current.title;
      companyController.text = current.companyName;
      contactController.text = current.contactName;
      valueController.text = current.value.toStringAsFixed(2).replaceAll('.', ',');
      productController.text = current.product ?? '';
    } else {
      stageId = controller.stages.isEmpty ? null : controller.stages.first.id;
    }
    setState(() {});
  }

  @override
  void dispose() {
    titleController.dispose();
    companyController.dispose();
    contactController.dispose();
    valueController.dispose();
    productController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = controller.loadState.value;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 40),
      children: <Widget>[
        _FormHeader(
          title: editing ? 'Editar oportunidade' : 'Nova oportunidade',
          subtitle: editing
              ? 'Atualize os dados e a previsão desta negociação.'
              : 'Vincule um lead e adicione a oportunidade ao pipeline.',
          onBack: _back,
        ),
        const SizedBox(height: 20),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: state == ScreenState.loading || state == ScreenState.initial
                ? const Card(
                    child: Padding(
                      padding: EdgeInsets.all(52),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                : state == ScreenState.error
                    ? _FormLoadError(
                        message: controller.errorMessage.value ??
                            'Não foi possível abrir o formulário.',
                        correlationId: controller.correlationId.value,
                        onRetry: _initialize,
                      )
                    : controller.leads.value.isEmpty
                        ? _NoLeadsState(
                            onCreateLead: () => context.go('/leads/new'),
                          )
                        : _buildForm(context),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Lead e negociação', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                initialValue: leadId,
                decoration: const InputDecoration(
                  labelText: 'Lead *',
                  prefixIcon: Icon(Icons.person_search_outlined),
                ),
                items: controller.leads.value
                    .map(
                      (LeadModel lead) => DropdownMenuItem<String>(
                        value: lead.id,
                        child: Text(
                          '${lead.name}${lead.company == null ? '' : ' • ${lead.company}'}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (String? value) {
                  setState(() => leadId = value);
                  if (value != null) _fillFromLead(value);
                },
                validator: (String? value) =>
                    value == null || value.isEmpty ? 'Selecione um lead' : null,
              ),
              const SizedBox(height: 14),
              _ResponsiveFormFields(
                children: <Widget>[
                  TextFormField(
                    controller: companyController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Empresa *',
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                    validator: _required,
                  ),
                  TextFormField(
                    controller: contactController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Contato *',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: _required,
                  ),
                  TextFormField(
                    controller: titleController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Título da oportunidade *',
                      prefixIcon: Icon(Icons.sell_outlined),
                    ),
                    validator: _required,
                  ),
                  TextFormField(
                    controller: valueController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Valor estimado',
                      prefixText: r'R$ ',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                  ),
                  TextFormField(
                    controller: productController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Produto ou serviço',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: source,
                    decoration: const InputDecoration(
                      labelText: 'Origem',
                      prefixIcon: Icon(Icons.ads_click_outlined),
                    ),
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem(value: 'manual', child: Text('Manual')),
                      DropdownMenuItem(value: 'website', child: Text('Site')),
                      DropdownMenuItem(value: 'whatsapp', child: Text('WhatsApp')),
                      DropdownMenuItem(value: 'instagram', child: Text('Instagram')),
                      DropdownMenuItem(value: 'referral', child: Text('Indicação')),
                      DropdownMenuItem(value: 'campaign', child: Text('Campanha')),
                      DropdownMenuItem(value: 'import', child: Text('Importação')),
                    ],
                    onChanged: (String? value) {
                      if (value != null) setState(() => source = value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 20),
              Text('Etapa e previsão', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 18),
              _ResponsiveFormFields(
                children: <Widget>[
                  DropdownButtonFormField<String>(
                    initialValue: stageId,
                    decoration: const InputDecoration(
                      labelText: 'Etapa *',
                      prefixIcon: Icon(Icons.view_kanban_outlined),
                    ),
                    items: controller.stages
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
                        if (value == PipelineStageIds.closed &&
                            outcome == OpportunityOutcomes.open) {
                          outcome = OpportunityOutcomes.won;
                        } else if (value != PipelineStageIds.closed) {
                          outcome = OpportunityOutcomes.open;
                        }
                      });
                    },
                    validator: (String? value) =>
                        value == null ? 'Selecione uma etapa' : null,
                  ),
                  DropdownButtonFormField<String?>(
                    initialValue: ownerId,
                    decoration: const InputDecoration(
                      labelText: 'Responsável',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    items: <DropdownMenuItem<String?>>[
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Sem responsável'),
                      ),
                      ...controller.owners.map(
                        (item) => DropdownMenuItem<String?>(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      ),
                    ],
                    onChanged: (String? value) => setState(() => ownerId = value),
                  ),
                ],
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
              const SizedBox(height: 22),
              Row(
                children: <Widget>[
                  const Icon(Icons.percent_rounded, color: AppColors.blue),
                  const SizedBox(width: 7),
                  Text('Probabilidade', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  Text(
                    '${probability.round()}%',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Slider(
                value: probability,
                max: 100,
                divisions: 20,
                label: '${probability.round()}%',
                onChanged: (double value) => setState(() => probability = value),
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: const Icon(Icons.event_outlined, color: AppColors.primary),
                title: const Text('Próxima atividade'),
                subtitle: Text(
                  nextActivityAt == null
                      ? 'Nenhuma atividade programada'
                      : DateFormat("dd/MM/yyyy 'às' HH:mm").format(nextActivityAt!),
                ),
                trailing: Wrap(
                  spacing: 4,
                  children: <Widget>[
                    if (nextActivityAt != null)
                      IconButton(
                        tooltip: 'Remover data',
                        onPressed: () => setState(() => nextActivityAt = null),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    OutlinedButton(
                      onPressed: _pickNextActivity,
                      child: Text(nextActivityAt == null ? 'Agendar' : 'Alterar'),
                    ),
                  ],
                ),
              ),
              if (controller.errorMessage.value != null) ...<Widget>[
                const SizedBox(height: 14),
                FormErrorBanner(
                  message: controller.errorMessage.value!,
                  correlationId: controller.correlationId.value,
                ),
              ],
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final saveButton = SizedBox(
                    width: constraints.maxWidth < 520 ? double.infinity : 230,
                    child: PrimaryLoadingButton(
                      label: editing ? 'Salvar alterações' : 'Criar oportunidade',
                      icon: Icons.check_rounded,
                      isLoading: controller.isSaving.value,
                      onPressed: _save,
                    ),
                  );
                  if (constraints.maxWidth < 520) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        saveButton,
                        TextButton(onPressed: _back, child: const Text('Cancelar')),
                      ],
                    );
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      TextButton(onPressed: _back, child: const Text('Cancelar')),
                      const SizedBox(width: 10),
                      saveButton,
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _fillFromLead(String selectedLeadId) {
    final lead = controller.leads.value.firstWhere(
      (LeadModel item) => item.id == selectedLeadId,
    );
    contactController.text = lead.name;
    companyController.text = lead.company ?? lead.name;
    source = lead.source;
    if (titleController.text.trim().isEmpty) {
      titleController.text = 'Oportunidade • ${lead.company ?? lead.name}';
    }
    setState(() {});
  }

  Future<void> _pickNextActivity() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = nextActivityAt;
    final initialDate = selectedDate == null || selectedDate.isBefore(today)
        ? today
        : selectedDate;
    final date = await showDatePicker(
      context: context,
      firstDate: today,
      lastDate: DateTime(now.year + 3),
      initialDate: initialDate,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(nextActivityAt ?? now),
    );
    if (time == null) return;
    setState(() {
      nextActivityAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final selectedOwner = controller.owners.where((item) => item.id == ownerId);
    final value = _parseCurrency(valueController.text);
    final input = OpportunityInput(
      leadId: leadId ?? '',
      stageId: stageId ?? '',
      title: titleController.text,
      companyName: companyController.text,
      contactName: contactController.text,
      value: value,
      probability: probability.round(),
      ownerId: ownerId,
      ownerName: selectedOwner.isEmpty ? null : selectedOwner.first.name,
      product: productController.text,
      source: source,
      outcome: outcome,
      nextActivityAt: nextActivityAt,
    );
    final saved = await controller.save(
      opportunityId: widget.opportunityId,
      input: input,
    );
    if (!mounted || saved == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          editing
              ? 'Oportunidade atualizada com sucesso.'
              : 'Oportunidade criada com sucesso.',
        ),
      ),
    );
    context.go('/pipeline/${saved.id}');
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/pipeline');
    }
  }

  static String? _required(String? value) {
    return (value?.trim().length ?? 0) < 2 ? 'Campo obrigatório' : null;
  }

  static double _parseCurrency(String value) {
    final clean = value.trim().replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(clean) ?? 0;
  }
}

class _FormHeader extends StatelessWidget {
  const _FormHeader({required this.title, required this.subtitle, required this.onBack});

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        IconButton.filledTonal(
          onPressed: onBack,
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResponsiveFormFields extends StatelessWidget {
  const _ResponsiveFormFields({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < 620) {
          return Column(
            children: children
                .expand((Widget child) => <Widget>[child, const SizedBox(height: 14)])
                .toList(growable: false),
          );
        }
        final width = (constraints.maxWidth - 14) / 2;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: children
              .map((Widget child) => SizedBox(width: width, child: child))
              .toList(growable: false),
        );
      },
    );
  }
}

class _NoLeadsState extends StatelessWidget {
  const _NoLeadsState({required this.onCreateLead});

  final VoidCallback onCreateLead;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 52),
        child: Column(
          children: <Widget>[
            const Icon(Icons.person_add_alt_1_outlined, size: 48, color: AppColors.primary),
            const SizedBox(height: 14),
            Text('Cadastre um lead primeiro', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 7),
            const Text(
              'Toda oportunidade precisa estar vinculada a um lead da empresa.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onCreateLead,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Cadastrar lead'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormLoadError extends StatelessWidget {
  const _FormLoadError({
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
