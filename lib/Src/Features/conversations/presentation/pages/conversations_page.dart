import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:agente_vendas_saas/Src/Core/di/service_locator.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
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
