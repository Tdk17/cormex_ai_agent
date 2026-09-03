import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:agente_vendas_saas/Src/Core/di/service_locator.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/conversations/domain/conversation_constants.dart';
import 'package:agente_vendas_saas/Src/Features/conversations/domain/conversation_start_input.dart';
import 'package:agente_vendas_saas/Src/Features/conversations/presentation/controllers/conversation_thread_controller.dart';
import 'package:agente_vendas_saas/Src/Features/conversations/presentation/controllers/conversations_controller.dart';
import 'package:agente_vendas_saas/Src/Features/conversations/presentation/widgets/conversation_list_panel.dart';
import 'package:agente_vendas_saas/Src/Features/conversations/presentation/widgets/conversation_thread_panel.dart';
import 'package:agente_vendas_saas/Src/Features/conversations/presentation/widgets/lead_context_panel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';

class ConversationsPage extends SignalStatefulWidget {
  const ConversationsPage({super.key, this.conversationId});

  final String? conversationId;

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  late final ConversationsController conversationsController;
  ConversationThreadController? threadController;

  @override
  void initState() {
    super.initState();
    conversationsController = sl<ConversationsController>();
    if (conversationsController.state.value == ScreenState.initial) {
      conversationsController.load();
    }
    _loadThread(widget.conversationId);
  }

  @override
  void didUpdateWidget(covariant ConversationsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId != widget.conversationId) {
      _loadThread(widget.conversationId);
    }
  }

  void _loadThread(String? conversationId) {
    if (conversationId == null) {
      threadController = null;
      return;
    }
    final next = sl<ConversationThreadController>();
    threadController = next;
    next.load(conversationId);
  }

  void _showLeadContext(BuildContext context) {
    final controller = threadController;
    if (controller == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) => FractionallySizedBox(
        heightFactor: 0.88,
        child: LeadContextPanel(
          controller: controller,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Future<void> _showStartConversation() async {
    conversationsController.clearActionError();
    final input = await showDialog<ConversationStartInput>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const _StartConversationDialog(),
    );
    if (input == null || !mounted) return;
    final conversation = await conversationsController.startConversation(input);
    if (!mounted || conversation == null) return;
    context.go('/conversations/${conversation.id}');
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = widget.conversationId;
    final selectedThread = threadController;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final isWide = constraints.maxWidth >= 1180;
        final isMedium = constraints.maxWidth >= 760;

        if (!isMedium) {
          if (selectedId == null || selectedThread == null) {
            return ConversationListPanel(
              controller: conversationsController,
              selectedConversationId: selectedId,
              onStart: _showStartConversation,
              onOpen: (String id) => context.go('/conversations/$id'),
            );
          }
          return ConversationThreadPanel(
            key: ValueKey<String>(selectedId),
            controller: selectedThread,
            compact: true,
            onBack: () => context.go('/conversations'),
            onShowLead: () => _showLeadContext(context),
          );
        }

        return Container(
          margin: const EdgeInsets.all(18),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: isWide ? 340 : 310,
                child: ConversationListPanel(
                  controller: conversationsController,
                  selectedConversationId: selectedId,
                  embedded: true,
                  onStart: _showStartConversation,
                  onOpen: (String id) => context.go('/conversations/$id'),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: selectedThread == null
                    ? const _NoConversationSelected()
                    : ConversationThreadPanel(
                        key: ValueKey<String>(selectedId!),
                        controller: selectedThread,
                        onShowLead: isWide
                            ? null
                            : () => _showLeadContext(context),
                      ),
              ),
              if (isWide && selectedThread != null) ...<Widget>[
                const VerticalDivider(width: 1),
                SizedBox(
                  width: 310,
                  child: LeadContextPanel(controller: selectedThread),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StartConversationDialog extends StatefulWidget {
  const _StartConversationDialog();

  @override
  State<_StartConversationDialog> createState() =>
      _StartConversationDialogState();
}

class _StartConversationDialogState extends State<_StartConversationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _leadIdController = TextEditingController();
  final _messageController = TextEditingController();
  String _channel = ConversationChannels.whatsapp;
  String _mode = ConversationModes.auto;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _leadIdController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Iniciar conversa'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Escolha quem fará o primeiro atendimento. No modo IA automática, o agente usa a configuração e a Base de Conhecimento da empresa.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 18),
                SegmentedButton<String>(
                  segments: const <ButtonSegment<String>>[
                    ButtonSegment<String>(
                      value: ConversationModes.auto,
                      icon: Icon(Icons.auto_awesome_rounded),
                      label: Text('IA automática'),
                    ),
                    ButtonSegment<String>(
                      value: ConversationModes.human,
                      icon: Icon(Icons.support_agent_rounded),
                      label: Text('Eu converso'),
                    ),
                  ],
                  selected: <String>{_mode},
                  showSelectedIcon: false,
                  onSelectionChanged: (Set<String> value) {
                    setState(() => _mode = value.first);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _channel,
                  decoration: const InputDecoration(labelText: 'Canal'),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(
                      value: ConversationChannels.whatsapp,
                      child: Text('WhatsApp'),
                    ),
                    DropdownMenuItem<String>(
                      value: ConversationChannels.instagram,
                      child: Text('Instagram'),
                    ),
                    DropdownMenuItem<String>(
                      value: ConversationChannels.email,
                      child: Text('E-mail'),
                    ),
                    DropdownMenuItem<String>(
                      value: ConversationChannels.webchat,
                      child: Text('Webchat'),
                    ),
                  ],
                  onChanged: (String? value) {
                    if (value != null) setState(() => _channel = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do contato',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefone com DDD',
                    hintText: '+55 47 99999-9999',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail (opcional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _leadIdController,
                  decoration: const InputDecoration(
                    labelText: 'ID de um lead existente (opcional)',
                  ),
                  validator: (_) {
                    final hasDestination =
                        _leadIdController.text.trim().isNotEmpty ||
                        _phoneController.text.trim().isNotEmpty ||
                        _emailController.text.trim().isNotEmpty;
                    return hasDestination
                        ? null
                        : 'Informe telefone, e-mail ou ID do lead.';
                  },
                ),
                if (_mode == ConversationModes.human) ...<Widget>[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _messageController,
                    minLines: 3,
                    maxLines: 6,
                    maxLength: 4000,
                    decoration: const InputDecoration(
                      labelText: 'Primeira mensagem',
                    ),
                    validator: (String? value) =>
                        (value?.trim().length ?? 0) < 2
                        ? 'Escreva a primeira mensagem.'
                        : null,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: Icon(
            _mode == ConversationModes.auto
                ? Icons.auto_awesome_rounded
                : Icons.send_rounded,
          ),
          label: Text(
            _mode == ConversationModes.auto
                ? 'Iniciar com IA'
                : 'Enviar mensagem',
          ),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).pop(
      ConversationStartInput(
        channel: _channel,
        mode: _mode,
        leadId: _leadIdController.text,
        contactName: _nameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        initialMessage:
            _mode == ConversationModes.human ? _messageController.text : null,
      ),
    );
  }
}

class _NoConversationSelected extends StatelessWidget {
  const _NoConversationSelected();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.forum_outlined,
                size: 35,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Selecione uma conversa',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 7),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 360),
              child: Text(
                'Escolha um contato à esquerda para acompanhar o histórico e continuar o atendimento.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
