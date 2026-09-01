import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:agente_vendas_saas/Src/Core/di/service_locator.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/agent/domain/agent_constants.dart';
import 'package:agente_vendas_saas/Src/Features/agent/presentation/controllers/agent_settings_controller.dart';
import 'package:agente_vendas_saas/Src/Features/agent/presentation/widgets/agent_page_header.dart';
import 'package:agente_vendas_saas/Src/Shared/components/form_error_banner.dart';
import 'package:agente_vendas_saas/Src/Shared/components/primary_loading_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';

class AgentSettingsPage extends SignalWidget {
  const AgentSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = sl<AgentSettingsController>();
    final state = controller.state.value;
    final agent = controller.agent.value;

    return Column(
      children: <Widget>[
        AgentPageHeader(
          activeSection: 'settings',
          isActive: controller.isActive.value,
          agentName: controller.name.value,
        ),
        Expanded(
          child: state == ScreenState.loading && agent == null
              ? const Center(child: CircularProgressIndicator())
              : state == ScreenState.error && agent == null
              ? _LoadError(controller: controller)
              : _SettingsForm(controller: controller, state: state),
        ),
      ],
    );
  }
}

class _SettingsForm extends SignalWidget {
  const _SettingsForm({required this.controller, required this.state});

  final AgentSettingsController controller;
  final ScreenState state;

  @override
  Widget build(BuildContext context) {
    final revision = controller.formRevision.value;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 48),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _AgentOverview(controller: controller),
                if (state == ScreenState.empty) ...<Widget>[
                  const SizedBox(height: 14),
                  const _InfoBanner(
                    message:
                        'Este workspace ainda não possui uma configuração completa. Preencha os campos e salve para criar o agente.',
                  ),
                ],
                if (controller.errorMessage.value != null) ...<Widget>[
                  const SizedBox(height: 14),
                  FormErrorBanner(
                    message: controller.errorMessage.value!,
                    correlationId: controller.correlationId.value,
                  ),
                ],
                if (controller.successMessage.value != null) ...<Widget>[
                  const SizedBox(height: 14),
                  _SuccessBanner(message: controller.successMessage.value!),
                ],
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final wide = constraints.maxWidth >= 840;
                    final identity = _IdentitySection(
                      key: ValueKey<String>('identity-$revision'),
                      controller: controller,
                    );
                    final offer = _OfferSection(
                      key: ValueKey<String>('offer-$revision'),
                      controller: controller,
                    );
                    if (!wide) {
                      return Column(
                        children: <Widget>[
                          identity,
                          const SizedBox(height: 16),
                          offer,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(child: identity),
                        const SizedBox(width: 16),
                        Expanded(child: offer),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                _ModeSection(controller: controller),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final rules = _ListSection(
                      title: 'Regras obrigatórias',
                      description:
                          'Limites que o agente nunca deve ignorar durante uma negociação.',
                      icon: Icons.gpp_good_outlined,
                      items: controller.rules.value,
                      hint: 'Ex.: nunca prometer desconto sem autorização',
                      onAdd: controller.addRule,
                      onRemove: controller.removeRule,
                    );
                    final questions = _ListSection(
                      title: 'Perguntas de qualificação',
                      description:
                          'Informações que ajudam a identificar intenção e potencial de compra.',
                      icon: Icons.quiz_outlined,
                      items: controller.qualificationQuestions.value,
                      hint: 'Ex.: qual é o tamanho da sua equipe?',
                      onAdd: controller.addQualificationQuestion,
                      onRemove: controller.removeQualificationQuestion,
                    );
                    if (constraints.maxWidth < 840) {
                      return Column(
                        children: <Widget>[
                          rules,
                          const SizedBox(height: 16),
                          questions,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(child: rules),
                        const SizedBox(width: 16),
                        Expanded(child: questions),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                _ScheduleSection(controller: controller),
                const SizedBox(height: 16),
                _PoliciesSection(
                  key: ValueKey<String>('policies-$revision'),
                  controller: controller,
                ),
                const SizedBox(height: 18),
                _SaveBar(controller: controller),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AgentOverview extends SignalWidget {
  const _AgentOverview({required this.controller});

  final AgentSettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF16213E), Color(0xFF0B6B61)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'CENTRAL DE INTELIGÊNCIA COMERCIAL',
                style: TextStyle(
                  color: Color(0xFF8DE3CE),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                controller.name.value.trim().isEmpty
                    ? 'Configure seu agente de vendas'
                    : controller.name.value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                controller.objective.value.trim().isEmpty
                    ? 'Defina como a IA deve abordar, qualificar e conduzir seus leads.'
                    : controller.objective.value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.76),
                  height: 1.4,
                ),
              ),
            ],
          );
          final action = FilledButton.tonalIcon(
            onPressed: () => context.go('/agent/test'),
            icon: const Icon(Icons.science_outlined),
            label: const Text('Abrir console de teste'),
          );
          if (constraints.maxWidth < 650) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[details, const SizedBox(height: 16), action],
            );
          }
          return Row(
            children: <Widget>[
              Expanded(child: details),
              const SizedBox(width: 24),
              action,
            ],
          );
        },
      ),
    );
  }
}

class _IdentitySection extends StatelessWidget {
  const _IdentitySection({super.key, required this.controller});

  final AgentSettingsController controller;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Identidade e comportamento',
      description: 'Defina quem o agente representa durante a conversa.',
      icon: Icons.psychology_outlined,
      children: <Widget>[
        TextFormField(
          initialValue: controller.name.value,
          maxLength: 80,
          onChanged: (String value) => controller.name.value = value,
          decoration: const InputDecoration(
            labelText: 'Nome do agente',
            hintText: 'Ex.: Clara',
            prefixIcon: Icon(Icons.smart_toy_outlined),
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          initialValue: controller.objective.value,
          minLines: 3,
          maxLines: 5,
          maxLength: 1000,
          onChanged: (String value) => controller.objective.value = value,
          decoration: const InputDecoration(
            labelText: 'Objetivo comercial',
            hintText:
                'Explique o resultado que o agente deve buscar com cada lead.',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          initialValue: controller.persona.value,
          minLines: 3,
          maxLines: 6,
          maxLength: 1500,
          onChanged: (String value) => controller.persona.value = value,
          decoration: const InputDecoration(
            labelText: 'Persona',
            hintText:
                'Descreva personalidade, experiência e forma de se comunicar.',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: controller.tone.value,
          decoration: const InputDecoration(
            labelText: 'Tom de voz',
            prefixIcon: Icon(Icons.record_voice_over_outlined),
          ),
          items: AgentTones.values
              .map(
                (String value) => DropdownMenuItem<String>(
                  value: value,
                  child: Text(_toneLabel(value)),
                ),
              )
              .toList(growable: false),
          onChanged: (String? value) {
            if (value != null) controller.tone.value = value;
          },
        ),
      ],
    );
  }
}

class _OfferSection extends StatelessWidget {
  const _OfferSection({super.key, required this.controller});

  final AgentSettingsController controller;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Produto e abertura',
      description:
          'Contexto comercial principal usado para apresentar a oferta.',
      icon: Icons.inventory_2_outlined,
      children: <Widget>[
        TextFormField(
          initialValue: controller.productOffer.value,
          minLines: 5,
          maxLines: 9,
          maxLength: 1500,
          onChanged: (String value) => controller.productOffer.value = value,
          decoration: const InputDecoration(
            labelText: 'Produto ou oferta',
            hintText:
                'Descreva o que é vendido, público, benefícios, preço e condições permitidas.',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          initialValue: controller.initialMessage.value,
          minLines: 4,
          maxLines: 7,
          maxLength: 1000,
          onChanged: (String value) => controller.initialMessage.value = value,
          decoration: const InputDecoration(
            labelText: 'Mensagem inicial',
            hintText: 'Primeira abordagem usada para iniciar uma conversa.',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}

class _ModeSection extends SignalWidget {
  const _ModeSection({required this.controller});

  final AgentSettingsController controller;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Modo de operação',
      description:
          'Controle até onde a IA pode agir antes da participação de um vendedor.',
      icon: Icons.account_tree_outlined,
      trailing: Switch.adaptive(
        value: controller.isActive.value,
        onChanged: (bool value) => controller.isActive.value = value,
      ),
      children: <Widget>[
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: AgentModes.values
              .map(
                (String mode) => _ModeCard(
                  mode: mode,
                  selected: controller.mode.value == mode,
                  onTap: () => controller.mode.value = mode,
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 12),
        Text(
          controller.isActive.value
              ? 'O agente será considerado ativo após o backend validar e salvar toda a configuração.'
              : 'O agente está inativo e não deve iniciar respostas automáticas.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final String mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Material(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.background,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  _modeIcon(mode),
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _modeLabel(mode),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _modeDescription(mode),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  size: 19,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ListSection extends StatelessWidget {
  const _ListSection({
    required this.title,
    required this.description,
    required this.icon,
    required this.items,
    required this.hint,
    required this.onAdd,
    required this.onRemove,
  });

  final String title;
  final String description;
  final IconData icon;
  final List<String> items;
  final String hint;
  final ValueChanged<String> onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: title,
      description: description,
      icon: icon,
      children: <Widget>[
        _StringListEditor(
          items: items,
          hint: hint,
          onAdd: onAdd,
          onRemove: onRemove,
        ),
      ],
    );
  }
}

class _StringListEditor extends StatefulWidget {
  const _StringListEditor({
    required this.items,
    required this.hint,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> items;
  final String hint;
  final ValueChanged<String> onAdd;
  final ValueChanged<int> onRemove;

  @override
  State<_StringListEditor> createState() => _StringListEditorState();
}

class _StringListEditorState extends State<_StringListEditor> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  void _add() {
    final value = _textController.text.trim();
    if (value.length < 3) return;
    widget.onAdd(value);
    _textController.clear();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int index = 0; index < widget.items.length; index++)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(11, 8, 5, 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(child: Text(widget.items[index])),
                IconButton(
                  tooltip: 'Remover',
                  onPressed: () => widget.onRemove(index),
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
              ],
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _textController,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _add(),
                decoration: InputDecoration(hintText: widget.hint),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Adicionar',
              onPressed: _add,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
      ],
    );
  }
}

class _ScheduleSection extends SignalWidget {
  const _ScheduleSection({required this.controller});

  final AgentSettingsController controller;

  Future<void> _pickTime(
    BuildContext context,
    String current,
    ValueChanged<String> onSelected,
  ) async {
    final parts = current.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 8,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
    final result = await showTimePicker(context: context, initialTime: initial);
    if (result == null) return;
    onSelected(
      '${result.hour.toString().padLeft(2, '0')}:${result.minute.toString().padLeft(2, '0')}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Horário de atendimento',
      description:
          'Defina quando o agente pode operar. O backend deve aplicar o fuso do workspace.',
      icon: Icons.schedule_rounded,
      trailing: Switch.adaptive(
        value: controller.scheduleEnabled.value,
        onChanged: (bool value) => controller.scheduleEnabled.value = value,
      ),
      children: <Widget>[
        IgnorePointer(
          ignoring: !controller.scheduleEnabled.value,
          child: Opacity(
            opacity: controller.scheduleEnabled.value ? 1 : 0.48,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Dias ativos',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: List<Widget>.generate(
                    7,
                    (int index) => FilterChip(
                      label: Text(_dayLabel(index + 1)),
                      selected: controller.scheduleDays.value.contains(
                        index + 1,
                      ),
                      onSelected: (_) =>
                          controller.toggleScheduleDay(index + 1),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    _TimeButton(
                      label: 'Início',
                      value: controller.scheduleStartTime.value,
                      onPressed: () => _pickTime(
                        context,
                        controller.scheduleStartTime.value,
                        (String value) =>
                            controller.scheduleStartTime.value = value,
                      ),
                    ),
                    _TimeButton(
                      label: 'Fim',
                      value: controller.scheduleEndTime.value,
                      onPressed: () => _pickTime(
                        context,
                        controller.scheduleEndTime.value,
                        (String value) =>
                            controller.scheduleEndTime.value = value,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            Icons.public_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            controller.scheduleTimezone.value,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final String label;
  final String value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.schedule_rounded, size: 18),
      label: Text('$label: $value'),
    );
  }
}

class _PoliciesSection extends SignalWidget {
  const _PoliciesSection({super.key, required this.controller});

  final AgentSettingsController controller;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Políticas e guardrails',
      description:
          'Limites funcionais aplicados pelo backend antes de aceitar uma resposta.',
      icon: Icons.shield_outlined,
      children: <Widget>[
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final responseLimit = _NumberPolicy(
              label: 'Tamanho máximo da resposta',
              value: '${controller.maxResponseCharacters.value} caracteres',
              child: Slider(
                min: 100,
                max: 4000,
                divisions: 39,
                value: controller.maxResponseCharacters.value
                    .clamp(100, 4000)
                    .toDouble(),
                onChanged: (double value) =>
                    controller.maxResponseCharacters.value = value.round(),
              ),
            );
            final attempts = _NumberPolicy(
              label: 'Tentativas antes de chamar humano',
              value: '${controller.maxAttemptsBeforeHandoff.value}',
              child: Slider(
                min: 1,
                max: 10,
                divisions: 9,
                value: controller.maxAttemptsBeforeHandoff.value
                    .clamp(1, 10)
                    .toDouble(),
                onChanged: (double value) =>
                    controller.maxAttemptsBeforeHandoff.value = value.round(),
              ),
            );
            if (constraints.maxWidth < 700) {
              return Column(
                children: <Widget>[
                  responseLimit,
                  const SizedBox(height: 12),
                  attempts,
                ],
              );
            }
            return Row(
              children: <Widget>[
                Expanded(child: responseLimit),
                const SizedBox(width: 14),
                Expanded(child: attempts),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: <Widget>[
            _PolicySwitch(
              label: 'Perguntar nome quando ausente',
              value: controller.askForName.value,
              onChanged: (bool value) => controller.askForName.value = value,
            ),
            _PolicySwitch(
              label: 'Solicitar telefone quando necessário',
              value: controller.askForPhone.value,
              onChanged: (bool value) => controller.askForPhone.value = value,
            ),
            _PolicySwitch(
              label: 'Permitir apresentar preço',
              value: controller.allowPricePresentation.value,
              onChanged: (bool value) =>
                  controller.allowPricePresentation.value = value,
            ),
            _PolicySwitch(
              label: 'Transferir quando o cliente pedir',
              value: controller.handoffOnRequest.value,
              onChanged: (bool value) =>
                  controller.handoffOnRequest.value = value,
            ),
            _PolicySwitch(
              label: 'Permitir follow-up',
              value: controller.allowFollowUp.value,
              onChanged: (bool value) => controller.allowFollowUp.value = value,
            ),
          ],
        ),
        if (controller.allowFollowUp.value) ...<Widget>[
          const SizedBox(height: 14),
          SizedBox(
            width: 330,
            child: TextFormField(
              initialValue: '${controller.followUpDelayMinutes.value}',
              keyboardType: TextInputType.number,
              onChanged: (String value) {
                final parsed = int.tryParse(value);
                if (parsed != null)
                  controller.followUpDelayMinutes.value = parsed;
              },
              decoration: const InputDecoration(
                labelText: 'Aguardar antes do follow-up (minutos)',
                prefixIcon: Icon(Icons.update_rounded),
                helperText: 'Entre 5 minutos e 10.080 minutos (7 dias).',
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _NumberPolicy extends StatelessWidget {
  const _NumberPolicy({
    required this.label,
    required this.value,
    required this.child,
  });

  final String label;
  final String value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }
}

class _PolicySwitch extends StatelessWidget {
  const _PolicySwitch({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 330,
      padding: const EdgeInsets.fromLTRB(12, 3, 4, 3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SaveBar extends SignalWidget {
  const _SaveBar({required this.controller});

  final AgentSettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final text = const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Salvar e versionar configuração',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 3),
                Text(
                  'O backend valida o contrato, registra a versão e mantém a auditoria da alteração.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            );
            final buttons = Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextButton(
                  onPressed: controller.isSaving.value
                      ? null
                      : controller.resetToSaved,
                  child: const Text('Descartar alterações'),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 220,
                  child: PrimaryLoadingButton(
                    label: 'Salvar configuração',
                    icon: Icons.save_outlined,
                    isLoading: controller.isSaving.value,
                    onPressed: controller.save,
                  ),
                ),
              ],
            );
            if (constraints.maxWidth < 650) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[text, const SizedBox(height: 14), buttons],
              );
            }
            return Row(
              children: <Widget>[
                Expanded(child: text),
                const SizedBox(width: 18),
                buttons,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.children,
    this.trailing,
  });

  final String title;
  final String description;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 39,
                  height: 39,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.info_outline_rounded, color: AppColors.blue),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
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
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.accent,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.controller});

  final AgentSettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              FormErrorBanner(
                message:
                    controller.errorMessage.value ??
                    'Não foi possível carregar o agente.',
                correlationId: controller.correlationId.value,
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => controller.load(force: true),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _toneLabel(String value) => switch (value) {
  AgentTones.consultive => 'Consultivo',
  AgentTones.friendly => 'Amigável',
  AgentTones.direct => 'Direto',
  AgentTones.formal => 'Formal',
  AgentTones.persuasive => 'Persuasivo',
  _ => value,
};

String _modeLabel(String value) => switch (value) {
  AgentModes.auto => 'Automático',
  AgentModes.assist => 'Assistido',
  AgentModes.human => 'Humano',
  _ => value,
};

String _modeDescription(String value) => switch (value) {
  AgentModes.auto =>
    'A IA pode gerar e enviar respostas aprovadas pelas regras.',
  AgentModes.assist =>
    'A IA sugere respostas, mas um vendedor confirma o envio.',
  AgentModes.human =>
    'A IA fica suspensa e o atendimento permanece com a equipe.',
  _ => '',
};

IconData _modeIcon(String value) => switch (value) {
  AgentModes.auto => Icons.auto_awesome_rounded,
  AgentModes.assist => Icons.rate_review_outlined,
  AgentModes.human => Icons.support_agent_rounded,
  _ => Icons.settings_outlined,
};

String _dayLabel(int day) => switch (day) {
  1 => 'Seg',
  2 => 'Ter',
  3 => 'Qua',
  4 => 'Qui',
  5 => 'Sex',
  6 => 'Sáb',
  7 => 'Dom',
  _ => '$day',
};
