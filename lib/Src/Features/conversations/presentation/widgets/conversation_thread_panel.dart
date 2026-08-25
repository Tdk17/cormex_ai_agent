import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/conversations/domain/conversation_constants.dart';
import 'package:agente_vendas_saas/Src/Features/conversations/presentation/controllers/conversation_thread_controller.dart';
import 'package:agente_vendas_saas/Src/Shared/components/form_error_banner.dart';
import 'package:agente_vendas_saas/Src/Shared/models/conversation_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signals/signals_flutter.dart';

class ConversationThreadPanel extends SignalStatefulWidget {
  const ConversationThreadPanel({
    super.key,
    required this.controller,
    this.compact = false,
    this.onBack,
    this.onShowLead,
  });

  final ConversationThreadController controller;
  final bool compact;
  final VoidCallback? onBack;
  final VoidCallback? onShowLead;

  @override
  State<ConversationThreadPanel> createState() =>
      _ConversationThreadPanelState();
}

class _ConversationThreadPanelState extends State<ConversationThreadPanel> {
  late final TextEditingController _composerController;
  late final ScrollController _messagesController;
  String? _lastMessageId;
  bool _didInitialScroll = false;

  @override
  void initState() {
    super.initState();
    _composerController = TextEditingController();
    _messagesController = ScrollController()..addListener(_onMessagesScroll);
  }

  void _onMessagesScroll() {
    if (_messagesController.hasClients &&
        _messagesController.position.pixels < 100 &&
        widget.controller.hasOlderMessages &&
        !widget.controller.isLoadingOlder.value) {
      _loadOlderPreservingPosition();
    }
  }

  Future<void> _loadOlderPreservingPosition() async {
    if (!_messagesController.hasClients) return;
    final previousMax = _messagesController.position.maxScrollExtent;
    await widget.controller.loadOlder();
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_messagesController.hasClients) return;
      final delta = _messagesController.position.maxScrollExtent - previousMax;
      _messagesController.jumpTo(
        (_messagesController.offset + delta).clamp(
          0,
          _messagesController.position.maxScrollExtent,
        ).toDouble(),
      );
    });
  }

  Future<void> _send() async {
    final sent = await widget.controller.send(_composerController.text);
    if (!mounted || !sent) return;
    _composerController.clear();
    _scrollToBottom(animated: true);
  }

  void _scrollToBottom({required bool animated}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_messagesController.hasClients) return;
      final target = _messagesController.position.maxScrollExtent;
      if (animated) {
        _messagesController.animateTo(
          target,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      } else {
        _messagesController.jumpTo(target);
      }
    });
  }

  void _syncScroll(List<MessageModel> messages) {
    final lastId = messages.isEmpty ? null : messages.last.id;
    if (!_didInitialScroll && messages.isNotEmpty) {
      _didInitialScroll = true;
      _lastMessageId = lastId;
      _scrollToBottom(animated: false);
      return;
    }
    if (lastId != null && lastId != _lastMessageId) {
      final isNearBottom = !_messagesController.hasClients ||
          _messagesController.position.extentAfter < 180;
      _lastMessageId = lastId;
      if (isNearBottom) _scrollToBottom(animated: true);
    }
  }

  @override
  void dispose() {
    _composerController.dispose();
    _messagesController
      ..removeListener(_onMessagesScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final state = controller.state.value;
    final conversation = controller.conversation.value;
    final messages = controller.messages.value;
    _syncScroll(messages);

    if (state == ScreenState.loading && conversation == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state == ScreenState.error) {
      return _ThreadError(
        message: controller.errorMessage.value ??
            'Não foi possível carregar a conversa.',
        correlationId: controller.correlationId.value,
        onBack: widget.onBack,
        onRetry: controller.reload,
      );
    }
    if (conversation == null) return const SizedBox.shrink();

    return ColoredBox(
      color: const Color(0xFFF8FAFC),
      child: SafeArea(
        top: widget.compact,
        child: Column(
          children: <Widget>[
            _ThreadHeader(
              controller: controller,
              conversation: conversation,
              onBack: widget.onBack,
              onShowLead: widget.onShowLead,
            ),
            if (state == ScreenState.loading)
              const LinearProgressIndicator(minHeight: 2),
            if (controller.actionError.value != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Stack(
                  children: <Widget>[
                    FormErrorBanner(
                      message: controller.actionError.value!,
                      correlationId: controller.correlationId.value,
                    ),
                    Positioned(
                      right: 2,
                      top: 2,
                      child: IconButton(
                        tooltip: 'Fechar aviso',
                        onPressed: controller.clearActionError,
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: messages.isEmpty
                  ? const _EmptyThread()
                  : ListView.builder(
                      controller: _messagesController,
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
                      itemCount: messages.length +
                          (controller.hasOlderMessages ||
                                  controller.isLoadingOlder.value
                              ? 1
                              : 0),
                      itemBuilder: (BuildContext context, int index) {
                        final hasLoader = controller.hasOlderMessages ||
                            controller.isLoadingOlder.value;
                        if (hasLoader && index == 0) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: controller.isLoadingOlder.value
                                  ? const SizedBox.square(
                                      dimension: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : TextButton.icon(
                                      onPressed: _loadOlderPreservingPosition,
                                      icon: const Icon(
                                        Icons.history_rounded,
                                        size: 18,
                                      ),
                                      label: const Text('Mensagens anteriores'),
                                    ),
                            ),
                          );
                        }
                        final messageIndex = hasLoader ? index - 1 : index;
                        return _MessageBubble(
                          message: messages[messageIndex],
                          previous: messageIndex > 0
                              ? messages[messageIndex - 1]
                              : null,
                        );
                      },
                    ),
            ),
            if (conversation.agentMode == ConversationModes.assist &&
                controller.suggestedReply.value?.trim().isNotEmpty == true)
              _SuggestedReply(
                content: controller.suggestedReply.value!,
                onUse: () {
                  _composerController.text = controller.suggestedReply.value!;
                  _composerController.selection = TextSelection.collapsed(
                    offset: _composerController.text.length,
                  );
                },
              ),
            _Composer(
              controller: _composerController,
              isSending: controller.isSending.value,
              isClosed: conversation.status == ConversationStatuses.closed,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreadHeader extends SignalWidget {
  const _ThreadHeader({
    required this.controller,
    required this.conversation,
    this.onBack,
    this.onShowLead,
  });

  final ConversationThreadController controller;
  final ConversationModel conversation;
  final VoidCallback? onBack;
  final VoidCallback? onShowLead;

  @override
  Widget build(BuildContext context) {
    final busy = controller.isChangingAssignment.value ||
        controller.isChangingMode.value;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final narrow = constraints.maxWidth < 690;
          final identity = Row(
            children: <Widget>[
              if (onBack != null)
                IconButton(
                  tooltip: 'Voltar para conversas',
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              CircleAvatar(
                radius: 21,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                foregroundColor: AppColors.primary,
                child: Text(
                  _initials(conversation.leadName),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      conversation.leadName.isEmpty
                          ? 'Lead sem nome'
                          : conversation.leadName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_channelLabel(conversation.channel)} • ${_statusLabel(conversation.status)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (onShowLead != null)
                IconButton(
                  tooltip: 'Dados do lead',
                  onPressed: onShowLead,
                  icon: const Icon(Icons.contact_page_outlined),
                ),
            ],
          );

          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: <Widget>[
              PopupMenuButton<String>(
                enabled: !busy,
                tooltip: 'Modo de atendimento',
                onSelected: controller.setMode,
                itemBuilder: (BuildContext context) => ConversationModes.values
                    .map(
                      (String mode) => PopupMenuItem<String>(
                        value: mode,
                        child: Row(
                          children: <Widget>[
                            Icon(
                              conversation.agentMode == mode
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              size: 18,
                              color: conversation.agentMode == mode
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 9),
                            Text(_modeLabel(mode)),
                          ],
                        ),
                      ),
                    )
                    .toList(growable: false),
                child: _HeaderAction(
                  icon: conversation.agentMode == ConversationModes.human
                      ? Icons.support_agent_rounded
                      : Icons.auto_awesome_rounded,
                  label: _modeLabel(conversation.agentMode),
                  loading: controller.isChangingMode.value,
                ),
              ),
              if (conversation.agentMode == ConversationModes.human)
                OutlinedButton.icon(
                  onPressed: busy ? null : controller.returnToAi,
                  icon: const Icon(Icons.smart_toy_outlined, size: 18),
                  label: const Text('Devolver para IA'),
                )
              else
                FilledButton.icon(
                  onPressed: busy ? null : controller.takeOver,
                  icon: const Icon(Icons.pan_tool_alt_outlined, size: 18),
                  label: const Text('Assumir conversa'),
                ),
              IconButton(
                tooltip: 'Atualizar conversa',
                onPressed: controller.state.value == ScreenState.loading
                    ? null
                    : () => controller.load(conversation.id, force: true),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                identity,
                const SizedBox(height: 10),
                actions,
              ],
            );
          }
          return Row(
            children: <Widget>[
              Expanded(child: identity),
              const SizedBox(width: 10),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.loading,
  });

  final IconData icon;
  final String label;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (loading)
            const SizedBox.square(
              dimension: 17,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 7),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 2),
          const Icon(Icons.arrow_drop_down_rounded, size: 18),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, this.previous});

  final MessageModel message;
  final MessageModel? previous;

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.border.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message.content,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ),
      );
    }

    final outbound = message.isOutbound;
    final ai = message.isAi;
    final bubbleColor = outbound
        ? ai
            ? const Color(0xFFEEE8FF)
            : AppColors.primary
        : Colors.white;
    final foreground = outbound && !ai ? Colors.white : AppColors.ink;
    final sameSender = previous?.senderType == message.senderType &&
        previous?.direction == message.direction;

    return Align(
      alignment: outbound ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        margin: EdgeInsets.only(top: sameSender ? 4 : 12),
        padding: const EdgeInsets.fromLTRB(13, 9, 11, 7),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: Radius.circular(outbound ? 15 : 4),
            bottomRight: Radius.circular(outbound ? 4 : 15),
          ),
          border: outbound
              ? null
              : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (!sameSender) ...<Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    ai
                        ? Icons.auto_awesome_rounded
                        : outbound
                            ? Icons.support_agent_rounded
                            : Icons.person_outline_rounded,
                    size: 13,
                    color: ai
                        ? const Color(0xFF7C3AED)
                        : foreground.withValues(alpha: 0.78),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    ai
                        ? 'Agente de IA'
                        : outbound
                            ? message.senderName ?? 'Atendente'
                            : message.senderName ?? 'Cliente',
                    style: TextStyle(
                      color: ai
                          ? const Color(0xFF7C3AED)
                          : foreground.withValues(alpha: 0.78),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
            ],
            SelectableText(
              message.content,
              style: TextStyle(color: foreground, height: 1.35),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  DateFormat('HH:mm').format(message.sentAt.toLocal()),
                  style: TextStyle(
                    color: foreground.withValues(alpha: 0.64),
                    fontSize: 9,
                  ),
                ),
                if (outbound) ...<Widget>[
                  const SizedBox(width: 4),
                  Icon(
                    message.status == 'failed'
                        ? Icons.error_outline_rounded
                        : message.status == 'read'
                            ? Icons.done_all_rounded
                            : Icons.done_rounded,
                    size: 13,
                    color: message.status == 'failed'
                        ? AppColors.danger
                        : foreground.withValues(alpha: 0.7),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestedReply extends StatelessWidget {
  const _SuggestedReply({required this.content, required this.onUse});

  final String content;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 5, 14, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEE8FF),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFD9CBFF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.auto_awesome_rounded,
            size: 19,
            color: Color(0xFF7C3AED),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Resposta sugerida pela IA',
                  style: TextStyle(
                    color: Color(0xFF6D28D9),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(onPressed: onUse, child: const Text('Usar')),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.isSending,
    required this.isClosed,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final bool isClosed;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isClosed && !isSending,
              minLines: 1,
              maxLines: 5,
              maxLength: 4000,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: isClosed
                    ? 'Conversa encerrada'
                    : 'Digite uma mensagem…',
                counterText: '',
              ),
            ),
          ),
          const SizedBox(width: 9),
          SizedBox.square(
            dimension: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              onPressed: isClosed || isSending ? null : onSend,
              child: isSending
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyThread extends StatelessWidget {
  const _EmptyThread();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Esta conversa ainda não possui mensagens.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _ThreadError extends StatelessWidget {
  const _ThreadError({
    required this.message,
    required this.correlationId,
    required this.onRetry,
    this.onBack,
  });

  final String message;
  final String? correlationId;
  final VoidCallback? onRetry;
  final VoidCallback? onBack;

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
              FormErrorBanner(message: message, correlationId: correlationId),
              const SizedBox(height: 14),
              if (onRetry != null)
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tentar novamente'),
                ),
              if (onBack != null) ...<Widget>[
                const SizedBox(height: 8),
                TextButton(onPressed: onBack, child: const Text('Voltar')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'L';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String _channelLabel(String value) => switch (value) {
      ConversationChannels.whatsapp => 'WhatsApp',
      ConversationChannels.instagram => 'Instagram',
      ConversationChannels.webchat => 'Webchat',
      ConversationChannels.email => 'E-mail',
      _ => value,
    };

String _statusLabel(String value) => switch (value) {
      ConversationStatuses.open => 'Aberta',
      ConversationStatuses.waitingCustomer => 'Aguardando cliente',
      ConversationStatuses.closed => 'Encerrada',
      _ => value,
    };

String _modeLabel(String value) => switch (value) {
      ConversationModes.auto => 'IA automática',
      ConversationModes.assist => 'IA assistida',
      ConversationModes.human => 'Atendimento humano',
      _ => value,
    };
