import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/conversations/domain/conversation_constants.dart';
import 'package:agente_vendas_saas/Src/Features/conversations/presentation/controllers/conversations_controller.dart';
import 'package:agente_vendas_saas/Src/Shared/components/form_error_banner.dart';
import 'package:agente_vendas_saas/Src/Shared/models/conversation_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signals/signals_flutter.dart';

class ConversationListPanel extends SignalStatefulWidget {
  const ConversationListPanel({
    super.key,
    required this.controller,
    required this.selectedConversationId,
    required this.onOpen,
    this.embedded = false,
  });

  final ConversationsController controller;
  final String? selectedConversationId;
  final ValueChanged<String> onOpen;
  final bool embedded;

  @override
  State<ConversationListPanel> createState() => _ConversationListPanelState();
}

class _ConversationListPanelState extends State<ConversationListPanel> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 240) {
      widget.controller.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final state = controller.state.value;
    final conversations = controller.conversations.value;
    final filters = controller.filters.value;

    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        top: !widget.embedded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Conversas',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Atendimento em um só lugar',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Atualizar conversas',
                    onPressed: state == ScreenState.loading
                        ? null
                        : () => controller.load(force: true),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                onChanged: controller.search,
                decoration: const InputDecoration(
                  hintText: 'Buscar lead ou mensagem',
                  prefixIcon: Icon(Icons.search_rounded),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: <Widget>[
                  _FilterMenu(
                    label: filters.channel == null
                        ? 'Canal'
                        : _channelLabel(filters.channel!),
                    icon: Icons.chat_bubble_outline_rounded,
                    values: ConversationChannels.values,
                    labelFor: _channelLabel,
                    onSelected: controller.setChannel,
                  ),
                  const SizedBox(width: 7),
                  _FilterMenu(
                    label: filters.status == null
                        ? 'Status'
                        : _statusLabel(filters.status!),
                    icon: Icons.filter_alt_outlined,
                    values: ConversationStatuses.values,
                    labelFor: _statusLabel,
                    onSelected: controller.setStatus,
                  ),
                  if (controller.owners.value.isNotEmpty) ...<Widget>[
                    const SizedBox(width: 7),
                    _OwnerFilter(controller: controller),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            if (state == ScreenState.loading && conversations.isNotEmpty)
              const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: _body(
                context,
                state: state,
                conversations: conversations,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context, {
    required ScreenState state,
    required List<ConversationModel> conversations,
  }) {
    final controller = widget.controller;
    if (state == ScreenState.loading && conversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state == ScreenState.error && conversations.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          FormErrorBanner(
            message: controller.errorMessage.value ??
                'Não foi possível carregar as conversas.',
            correlationId: controller.correlationId.value,
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => controller.load(force: true),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tentar novamente'),
          ),
        ],
      );
    }
    if (state == ScreenState.empty || conversations.isEmpty) {
      return const _EmptyConversations();
    }

    return RefreshIndicator(
      onRefresh: () => controller.load(force: true),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: conversations.length + (controller.hasMore ? 1 : 0),
        itemBuilder: (BuildContext context, int index) {
          if (index == conversations.length) {
            return Padding(
              padding: const EdgeInsets.all(18),
              child: Center(
                child: controller.isLoadingMore.value
                    ? const SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : TextButton(
                        onPressed: controller.loadMore,
                        child: const Text('Carregar mais'),
                      ),
              ),
            );
          }
          final conversation = conversations[index];
          return _ConversationTile(
            conversation: conversation,
            selected: conversation.id == widget.selectedConversationId,
            onTap: () => widget.onOpen(conversation.id),
          );
        },
      ),
    );
  }
}

class _FilterMenu extends StatelessWidget {
  const _FilterMenu({
    required this.label,
    required this.icon,
    required this.values,
    required this.labelFor,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final List<String> values;
  final String Function(String) labelFor;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: label,
      onSelected: (String value) => onSelected(value.isEmpty ? null : value),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(value: '', child: Text('Todos')),
        ...values.map(
          (String value) => PopupMenuItem<String>(
            value: value,
            child: Text(labelFor(value)),
          ),
        ),
      ],
      child: _FilterChip(label: label, icon: icon),
    );
  }
}

class _OwnerFilter extends StatelessWidget {
  const _OwnerFilter({required this.controller});

  final ConversationsController controller;

  @override
  Widget build(BuildContext context) {
    final selected = controller.filters.value.assignedUserId;
    final match = controller.owners.value.where(
      (ConversationOwnerModel item) => item.id == selected,
    );
    return PopupMenuButton<String>(
      tooltip: 'Responsável',
      onSelected: (String value) =>
          controller.setOwner(value.isEmpty ? null : value),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(value: '', child: Text('Todos')),
        ...controller.owners.value.map(
          (ConversationOwnerModel owner) => PopupMenuItem<String>(
            value: owner.id,
            child: Text(owner.name),
          ),
        ),
      ],
      child: _FilterChip(
        label: match.isEmpty ? 'Responsável' : match.first.name,
        icon: Icons.person_outline_rounded,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 3),
          const Icon(Icons.arrow_drop_down_rounded, size: 17),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.selected,
    required this.onTap,
  });

  final ConversationModel conversation;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = conversation.unreadCount;
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.08)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            border: selected
                ? const Border(
                    left: BorderSide(color: AppColors.primary, width: 3),
                    bottom: BorderSide(color: AppColors.border),
                  )
                : const Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  CircleAvatar(
                    radius: 23,
                    backgroundColor: _channelColor(conversation.channel)
                        .withValues(alpha: 0.12),
                    foregroundColor: _channelColor(conversation.channel),
                    child: Text(
                      _initials(conversation.leadName),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Positioned(
                    right: -3,
                    bottom: -2,
                    child: Container(
                      width: 19,
                      height: 19,
                      decoration: BoxDecoration(
                        color: _channelColor(conversation.channel),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        _channelIcon(conversation.channel),
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            conversation.leadName.isEmpty
                                ? 'Lead sem nome'
                                : conversation.leadName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight:
                                  unread > 0 ? FontWeight.w800 : FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          _relativeTime(
                            conversation.lastMessageAt ?? conversation.updatedAt,
                          ),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            conversation.lastMessagePreview.isEmpty
                                ? 'Sem mensagens ainda'
                                : conversation.lastMessagePreview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: unread > 0
                                  ? AppColors.ink
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        if (unread > 0) ...<Widget>[
                          const SizedBox(width: 8),
                          Container(
                            constraints: const BoxConstraints(minWidth: 20),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.all(Radius.circular(20)),
                            ),
                            child: Text(
                              unread > 99 ? '99+' : '$unread',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        _TinyBadge(
                          label: _modeLabel(conversation.agentMode),
                          color: _modeColor(conversation.agentMode),
                        ),
                        const SizedBox(width: 6),
                        _TinyBadge(
                          label: _statusLabel(conversation.status),
                          color: _statusColor(conversation.status),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  const _TinyBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}

class _EmptyConversations extends StatelessWidget {
  const _EmptyConversations();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.mark_chat_unread_outlined,
              size: 42,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhuma conversa encontrada',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 5),
            const Text(
              'Ajuste os filtros ou aguarde a chegada de uma nova mensagem.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

String _relativeTime(DateTime value) {
  final local = value.toLocal();
  final now = DateTime.now();
  final difference = now.difference(local);
  if (difference.inMinutes < 1) return 'agora';
  if (difference.inHours < 1) return '${difference.inMinutes}min';
  if (difference.inHours < 24) return '${difference.inHours}h';
  if (difference.inDays < 7) return '${difference.inDays}d';
  return DateFormat('dd/MM').format(local);
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

IconData _channelIcon(String value) => switch (value) {
      ConversationChannels.whatsapp => Icons.phone_in_talk_rounded,
      ConversationChannels.instagram => Icons.photo_camera_outlined,
      ConversationChannels.webchat => Icons.language_rounded,
      ConversationChannels.email => Icons.alternate_email_rounded,
      _ => Icons.chat_bubble_outline_rounded,
    };

Color _channelColor(String value) => switch (value) {
      ConversationChannels.whatsapp => const Color(0xFF16A36A),
      ConversationChannels.instagram => const Color(0xFFC13584),
      ConversationChannels.webchat => AppColors.blue,
      ConversationChannels.email => const Color(0xFF7C3AED),
      _ => AppColors.textSecondary,
    };

String _modeLabel(String value) => switch (value) {
      ConversationModes.auto => 'IA automática',
      ConversationModes.assist => 'IA assistida',
      ConversationModes.human => 'Humano',
      _ => value,
    };

Color _modeColor(String value) => switch (value) {
      ConversationModes.auto => const Color(0xFF7C3AED),
      ConversationModes.assist => AppColors.blue,
      ConversationModes.human => AppColors.primary,
      _ => AppColors.textSecondary,
    };

String _statusLabel(String value) => switch (value) {
      ConversationStatuses.open => 'Aberta',
      ConversationStatuses.waitingCustomer => 'Aguardando cliente',
      ConversationStatuses.closed => 'Encerrada',
      _ => value,
    };

Color _statusColor(String value) => switch (value) {
      ConversationStatuses.open => AppColors.accent,
      ConversationStatuses.waitingCustomer => AppColors.warning,
      ConversationStatuses.closed => AppColors.textSecondary,
      _ => AppColors.textSecondary,
    };
