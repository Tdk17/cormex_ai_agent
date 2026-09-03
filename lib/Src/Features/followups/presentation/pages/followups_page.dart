import 'dart:async';

import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:agente_vendas_saas/Src/Core/di/service_locator.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/followups/domain/followup_rule_input.dart';
import 'package:agente_vendas_saas/Src/Features/followups/presentation/controllers/followups_controller.dart';
import 'package:agente_vendas_saas/Src/Shared/components/form_error_banner.dart';
import 'package:agente_vendas_saas/Src/Shared/models/followup_models.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

class FollowUpsPage extends SignalStatefulWidget {
  const FollowUpsPage({super.key});

  @override
  State<FollowUpsPage> createState() => _FollowUpsPageState();
}

class _FollowUpsPageState extends State<FollowUpsPage> {
  late final FollowUpsController controller;

  @override
  void initState() {
    super.initState();
    controller = sl<FollowUpsController>();
    if (controller.state.value == ScreenState.initial) {
      unawaited(controller.load());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = controller.state.value;
    final rules = controller.rules.value;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 48),
      children: <Widget>[
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Follow-ups', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 5),
                const Text(
                  'Programe retomadas automáticas sem insistir depois de resposta ou perda.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
            FilledButton.icon(
              onPressed: controller.isMutating.value ? null : () => _openEditor(),
              icon: const Icon(Icons.add_alarm_rounded),
              label: const Text('Nova regra'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    onChanged: controller.search,
                    decoration: const InputDecoration(
                      hintText: 'Buscar regra de follow-up',
                      prefixIcon: Icon(Icons.search_rounded),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  tooltip: 'Atualizar',
                  onPressed: () => controller.load(force: true),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
        ),
        if (controller.errorMessage.value != null) ...<Widget>[
          const SizedBox(height: 14),
          FormErrorBanner(
            message: controller.errorMessage.value!,
            correlationId: controller.correlationId.value,
          ),
        ],
        if (controller.successMessage.value != null) ...<Widget>[
          const SizedBox(height: 14),
          _Feedback(message: controller.successMessage.value!),
        ],
        const SizedBox(height: 18),
        if (state == ScreenState.loading && rules.isEmpty)
          const Padding(
            padding: EdgeInsets.all(64),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (state == ScreenState.error && rules.isEmpty)
          Center(
            child: OutlinedButton.icon(
              onPressed: () => controller.load(force: true),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          )
        else if (rules.isEmpty)
          _EmptyFollowUps(onAdd: () => _openEditor())
        else ...<Widget>[
          if (state == ScreenState.loading)
            const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: 8),
          ...rules.map(
            (FollowUpRuleModel rule) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RuleCard(
                rule: rule,
                disabled: controller.isMutating.value,
                onToggle: (bool value) => controller.toggle(rule, value),
                onEdit: () => _openEditor(rule),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openEditor([FollowUpRuleModel? rule]) async {
    controller.clearFeedback();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>
          _FollowUpEditor(controller: controller, rule: rule),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.rule,
    required this.disabled,
    required this.onToggle,
    required this.onEdit,
  });

  final FollowUpRuleModel rule;
  final bool disabled;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: (rule.active ? AppColors.primary : AppColors.textSecondary)
                    .withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                Icons.schedule_send_outlined,
                color: rule.active ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(rule.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 5),
                  Text(
                    '${_delayLabel(rule.delayMinutes)} • ${_conditionLabel(rule.condition)} • ${_channelLabel(rule.channel)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    rule.message.isEmpty ? 'Mensagem definida pelo agente de IA.' : rule.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 7,
                    runSpacing: 6,
                    children: <Widget>[
                      _SmallBadge(label: '${rule.maxAttempts} tentativa(s)'),
                      if (rule.stopOnReply) const _SmallBadge(label: 'Para ao responder'),
                      if (rule.stopOnLost) const _SmallBadge(label: 'Para ao perder'),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Editar',
              onPressed: disabled ? null : onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            Switch.adaptive(
              value: rule.active,
              onChanged: disabled ? null : onToggle,
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowUpEditor extends StatefulWidget {
  const _FollowUpEditor({required this.controller, this.rule});

  final FollowUpsController controller;
  final FollowUpRuleModel? rule;

  @override
  State<_FollowUpEditor> createState() => _FollowUpEditorState();
}

class _FollowUpEditorState extends State<_FollowUpEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _delayController;
  late final TextEditingController _messageController;
  late final TextEditingController _attemptsController;
  late String _condition;
  late String _channel;
  late bool _active;
  late bool _stopOnReply;
  late bool _stopOnLost;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final rule = widget.rule;
    _nameController = TextEditingController(text: rule?.name ?? '');
    _delayController = TextEditingController(
      text: (rule?.delayMinutes ?? 60).toString(),
    );
    _messageController = TextEditingController(text: rule?.message ?? '');
    _attemptsController = TextEditingController(
      text: (rule?.maxAttempts ?? 1).toString(),
    );
    _condition = rule?.condition ?? 'no_reply';
    _channel = rule?.channel ?? 'whatsapp';
    _active = rule?.active ?? true;
    _stopOnReply = rule?.stopOnReply ?? true;
    _stopOnLost = rule?.stopOnLost ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _delayController.dispose();
    _messageController.dispose();
    _attemptsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.rule == null ? 'Nova regra de follow-up' : 'Editar follow-up'),
      content: SizedBox(
        width: 570,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome da regra'),
                  validator: (String? value) => (value?.trim().length ?? 0) < 3
                      ? 'Informe um nome.'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _condition,
                        decoration: const InputDecoration(labelText: 'Quando'),
                        items: const <DropdownMenuItem<String>>[
                          DropdownMenuItem(value: 'no_reply', child: Text('Sem resposta')),
                          DropdownMenuItem(value: 'lead_created', child: Text('Lead criado')),
                          DropdownMenuItem(value: 'stage_changed', child: Text('Mudou de etapa')),
                        ],
                        onChanged: (String? value) {
                          if (value != null) _condition = value;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _delayController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Aguardar (minutos)'),
                        validator: (String? value) {
                          final number = int.tryParse(value ?? '');
                          return number == null || number < 1
                              ? 'Informe um tempo válido.'
                              : null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _channel,
                        decoration: const InputDecoration(labelText: 'Canal'),
                        items: const <DropdownMenuItem<String>>[
                          DropdownMenuItem(value: 'whatsapp', child: Text('WhatsApp')),
                          DropdownMenuItem(value: 'email', child: Text('E-mail')),
                          DropdownMenuItem(value: 'instagram', child: Text('Instagram')),
                        ],
                        onChanged: (String? value) {
                          if (value != null) _channel = value;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _attemptsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Máximo de tentativas'),
                        validator: (String? value) {
                          final number = int.tryParse(value ?? '');
                          return number == null || number < 1 || number > 10
                              ? 'Use um valor entre 1 e 10.'
                              : null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _messageController,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    labelText: 'Mensagem (vazia = IA escreve conforme contexto)',
                    alignLabelWithHint: true,
                  ),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _active,
                  onChanged: (bool value) => setState(() => _active = value),
                  title: const Text('Regra ativa'),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _stopOnReply,
                  onChanged: (bool? value) =>
                      setState(() => _stopOnReply = value ?? true),
                  title: const Text('Parar assim que o cliente responder'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _stopOnLost,
                  onChanged: (bool? value) =>
                      setState(() => _stopOnLost = value ?? true),
                  title: const Text('Parar se a oportunidade for perdida ou encerrada'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                if (_error != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save_outlined),
          label: const Text('Salvar regra'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final rule = widget.rule;
    final success = await widget.controller.save(
      FollowUpRuleInput(
        name: _nameController.text,
        delayMinutes: int.parse(_delayController.text),
        condition: _condition,
        active: _active,
        channel: _channel,
        message: _messageController.text,
        maxAttempts: int.parse(_attemptsController.text),
        stopOnReply: _stopOnReply,
        stopOnLost: _stopOnLost,
        expectedVersion: rule?.version,
      ),
      followupId: rule?.id,
    );
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _error = widget.controller.errorMessage.value;
      });
    }
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

class _EmptyFollowUps extends StatelessWidget {
  const _EmptyFollowUps({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 54),
        child: Column(
          children: <Widget>[
            const Icon(Icons.schedule_send_outlined, size: 48, color: AppColors.primary),
            const SizedBox(height: 14),
            Text('Nenhuma regra configurada', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            const Text(
              'Crie uma retomada para a IA continuar o atendimento sem perder o timing.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_alarm_rounded),
              label: const Text('Criar primeira regra'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message),
    );
  }
}

String _conditionLabel(String value) => switch (value) {
      'lead_created' => 'Após criar o lead',
      'stage_changed' => 'Após mudança de etapa',
      _ => 'Sem resposta',
    };

String _channelLabel(String value) => switch (value) {
      'email' => 'E-mail',
      'instagram' => 'Instagram',
      _ => 'WhatsApp',
    };

String _delayLabel(int minutes) {
  if (minutes < 60) return '$minutes min';
  if (minutes % 1440 == 0) return '${minutes ~/ 1440} dia(s)';
  if (minutes % 60 == 0) return '${minutes ~/ 60} hora(s)';
  return '$minutes min';
}
