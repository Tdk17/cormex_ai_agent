import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:agente_vendas_saas/Src/Core/di/service_locator.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/leads/domain/lead_input.dart';
import 'package:agente_vendas_saas/Src/Features/leads/domain/lead_labels.dart';
import 'package:agente_vendas_saas/Src/Features/leads/presentation/controllers/lead_form_controller.dart';
import 'package:agente_vendas_saas/Src/Shared/components/form_error_banner.dart';
import 'package:agente_vendas_saas/Src/Shared/components/primary_loading_button.dart';
import 'package:agente_vendas_saas/Src/Shared/models/lead_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';

class LeadFormPage extends SignalStatefulWidget {
  const LeadFormPage({super.key, this.leadId});

  final String? leadId;

  @override
  State<LeadFormPage> createState() => _LeadFormPageState();
}

class _LeadFormPageState extends State<LeadFormPage> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final companyController = TextEditingController();
  final tagsController = TextEditingController();
  late final LeadFormController controller;

  String status = 'new';
  String source = 'manual';
  double score = 0;
  bool loadingLead = false;

  bool get editing => widget.leadId != null;

  @override
  void initState() {
    super.initState();
    controller = sl<LeadFormController>();
    if (editing) _loadLead();
  }

  Future<void> _loadLead() async {
    setState(() => loadingLead = true);
    final lead = await controller.load(widget.leadId!);
    if (!mounted) return;
    if (lead != null) _fill(lead);
    setState(() => loadingLead = false);
  }

  void _fill(LeadModel lead) {
    nameController.text = lead.name;
    phoneController.text = lead.phone ?? '';
    emailController.text = lead.email ?? '';
    companyController.text = lead.company ?? '';
    tagsController.text = lead.tags.join(', ');
    status = lead.status;
    source = lead.source;
    score = lead.score.toDouble();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    companyController.dispose();
    tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 40),
      children: <Widget>[
        _PageHeader(
          title: editing ? 'Editar lead' : 'Novo lead',
          subtitle: editing
              ? 'Atualize os dados comerciais e a qualificação do contato.'
              : 'Adicione um contato à sua base comercial.',
          onBack: _back,
        ),
        const SizedBox(height: 20),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: loadingLead
                ? const Card(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                : controller.loadState.value == ScreenState.error
                    ? _LoadError(
                        message: controller.errorMessage.value ??
                            'Não foi possível carregar este lead.',
                        correlationId: controller.correlationId.value,
                        onRetry: _loadLead,
                      )
                    : Card(
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: Form(
                            key: formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text('Dados do contato', style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 5),
                                const Text(
                                  'O nome e ao menos um canal de contato são obrigatórios.',
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 20),
                                _ResponsiveFields(
                                  children: <Widget>[
                                    TextFormField(
                                      controller: nameController,
                                      textCapitalization: TextCapitalization.words,
                                      decoration: const InputDecoration(
                                        labelText: 'Nome *',
                                        prefixIcon: Icon(Icons.person_outline_rounded),
                                      ),
                                      validator: (String? value) =>
                                          (value?.trim().length ?? 0) < 2
                                              ? 'Informe o nome do lead'
                                              : null,
                                    ),
                                    TextFormField(
                                      controller: companyController,
                                      textCapitalization: TextCapitalization.words,
                                      decoration: const InputDecoration(
                                        labelText: 'Empresa',
                                        prefixIcon: Icon(Icons.business_outlined),
                                      ),
                                    ),
                                    TextFormField(
                                      controller: emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: const InputDecoration(
                                        labelText: 'E-mail',
                                        prefixIcon: Icon(Icons.mail_outline_rounded),
                                      ),
                                    ),
                                    TextFormField(
                                      controller: phoneController,
                                      keyboardType: TextInputType.phone,
                                      decoration: const InputDecoration(
                                        labelText: 'Telefone / WhatsApp',
                                        prefixIcon: Icon(Icons.phone_outlined),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                const Divider(),
                                const SizedBox(height: 20),
                                Text('Qualificação', style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 18),
                                _ResponsiveFields(
                                  children: <Widget>[
                                    DropdownButtonFormField<String>(
                                      initialValue: status,
                                      decoration: const InputDecoration(labelText: 'Status'),
                                      items: LeadLabels.statuses.entries
                                          .map(
                                            (entry) => DropdownMenuItem<String>(
                                              value: entry.key,
                                              child: Text(entry.value),
                                            ),
                                          )
                                          .toList(growable: false),
                                      onChanged: (String? value) {
                                        if (value != null) setState(() => status = value);
                                      },
                                    ),
                                    DropdownButtonFormField<String>(
                                      initialValue: source,
                                      decoration: const InputDecoration(labelText: 'Origem'),
                                      items: LeadLabels.sources.entries
                                          .map(
                                            (entry) => DropdownMenuItem<String>(
                                              value: entry.key,
                                              child: Text(entry.value),
                                            ),
                                          )
                                          .toList(growable: false),
                                      onChanged: (String? value) {
                                        if (value != null) setState(() => source = value);
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: tagsController,
                                  decoration: const InputDecoration(
                                    labelText: 'Tags',
                                    hintText: 'Ex.: prioridade, inbound, enterprise',
                                    prefixIcon: Icon(Icons.sell_outlined),
                                    helperText: 'Separe as tags por vírgula.',
                                  ),
                                ),
                                const SizedBox(height: 22),
                                Row(
                                  children: <Widget>[
                                    const Icon(Icons.bolt_rounded, color: AppColors.warning),
                                    const SizedBox(width: 7),
                                    Text('Score', style: Theme.of(context).textTheme.titleMedium),
                                    const Spacer(),
                                    Text(
                                      score.round().toString(),
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                                Slider(
                                  value: score,
                                  max: 100,
                                  divisions: 20,
                                  label: score.round().toString(),
                                  onChanged: (double value) => setState(() => score = value),
                                ),
                                if (controller.errorMessage.value != null) ...<Widget>[
                                  const SizedBox(height: 12),
                                  FormErrorBanner(
                                    message: controller.errorMessage.value!,
                                    correlationId: controller.correlationId.value,
                                  ),
                                ],
                                const SizedBox(height: 24),
                                LayoutBuilder(
                                  builder: (BuildContext context, BoxConstraints constraints) {
                                    final save = SizedBox(
                                      width: constraints.maxWidth < 520 ? double.infinity : 220,
                                      child: PrimaryLoadingButton(
                                        label: editing ? 'Salvar alterações' : 'Cadastrar lead',
                                        isLoading: controller.isSaving.value,
                                        onPressed: _save,
                                        icon: Icons.check_rounded,
                                      ),
                                    );
                                    if (constraints.maxWidth < 520) {
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: <Widget>[
                                          save,
                                          const SizedBox(height: 8),
                                          TextButton(onPressed: _back, child: const Text('Cancelar')),
                                        ],
                                      );
                                    }
                                    return Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: <Widget>[
                                        TextButton(onPressed: _back, child: const Text('Cancelar')),
                                        const SizedBox(width: 10),
                                        save,
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final result = await controller.save(
      leadId: widget.leadId,
      input: LeadInput(
        name: nameController.text,
        phone: _clean(phoneController.text),
        email: _clean(emailController.text),
        company: _clean(companyController.text),
        source: source,
        status: status,
        tags: tagsController.text
            .split(',')
            .map((String value) => value.trim())
            .where((String value) => value.isNotEmpty)
            .toSet()
            .toList(growable: false),
        score: score.round(),
      ),
    );
    if (!mounted || result == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(editing ? 'Lead atualizado com sucesso.' : 'Lead criado com sucesso.')),
    );
    context.go('/leads/${result.id}');
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/leads');
    }
  }

  static String? _clean(String value) {
    final clean = value.trim();
    return clean.isEmpty ? null : clean;
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.title, required this.subtitle, required this.onBack});

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        IconButton.filledTonal(
          tooltip: 'Voltar',
          onPressed: onBack,
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

class _ResponsiveFields extends StatelessWidget {
  const _ResponsiveFields({required this.children});

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

class _LoadError extends StatelessWidget {
  const _LoadError({
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
