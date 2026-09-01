import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:agente_vendas_saas/Src/Core/di/service_locator.dart';
import 'package:agente_vendas_saas/Src/Features/agent/presentation/controllers/agent_settings_controller.dart';
import 'package:agente_vendas_saas/Src/Features/agent/presentation/controllers/agent_test_controller.dart';
import 'package:agente_vendas_saas/Src/Features/agent/presentation/widgets/agent_page_header.dart';
import 'package:agente_vendas_saas/Src/Shared/components/form_error_banner.dart';
import 'package:agente_vendas_saas/Src/Shared/models/agent_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signals/signals_flutter.dart';

class AgentTestPage extends SignalStatefulWidget {
  const AgentTestPage({super.key});

  @override
  State<AgentTestPage> createState() => _AgentTestPageState();
}

class _AgentTestPageState extends State<AgentTestPage> {
  late final AgentTestController controller;
  late final TextEditingController _messageController;
  late final ScrollController _scrollController;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    controller = sl<AgentTestController>();
    _messageController = TextEditingController();
    _scrollController = ScrollController();
  }

  Future<void> _send() async {
    final sent = await controller.send(_messageController.text);
    if (!mounted || !sent) return;
    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    controller.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = sl<AgentSettingsController>();
    final entries = controller.messages.value;
    if (entries.length != _lastMessageCount) {
      _lastMessageCount = entries.length;
      _scrollToBottom();
    }

    return Column(
      children: <Widget>[
        AgentPageHeader(
          activeSection: 'test',
          isActive: settings.isActive.value,
          agentName: settings.name.value,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final desktop = constraints.maxWidth >= 900;
                final contextPanel = _TestContextPanel(
                  controller: controller,
                  settings: settings,
                  compact: !desktop,
                );
                final chat = _SandboxChat(
                  entries: entries,
                  messageController: _messageController,
                  scrollController: _scrollController,
                  isSending: controller.isSending.value,
                  errorMessage: controller.errorMessage.value,
                  correlationId: controller.correlationId.value,
                  usage: controller.lastUsage.value,
                  onSend: _send,
                  onClear: controller.clearConversation,
                  onDismissError: controller.clearError,
                );
                if (!desktop) {
                  return Column(
                    children: <Widget>[
                      contextPanel,
                      const SizedBox(height: 12),
                      Expanded(child: chat),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SizedBox(width: 330, child: contextPanel),
                    const SizedBox(width: 14),
                    Expanded(child: chat),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _TestContextPanel extends SignalWidget {
  const _TestContextPanel({
    required this.controller,
    required this.settings,
    required this.compact,
  });

  final AgentTestController controller;
  final AgentSettingsController settings;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _AgentReadiness(settings: settings),
        const SizedBox(height: 15),
        const Text(
          'Lead de teste',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        const Text(
          'Esses dados são enviados somente ao sandbox da IA.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: controller.leadName.value,
          onChanged: (String value) => controller.leadName.value = value,
          decoration: const InputDecoration(
            labelText: 'Nome do lead *',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          initialValue: controller.leadCompany.value,
          onChanged: (String value) => controller.leadCompany.value = value,
          decoration: const InputDecoration(
            labelText: 'Empresa',
            prefixIcon: Icon(Icons.business_outlined),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          initialValue: controller.leadPhone.value,
          keyboardType: TextInputType.phone,
          onChanged: (String value) => controller.leadPhone.value = value,
          decoration: const InputDecoration(
            labelText: 'Telefone',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          initialValue: controller.leadEmail.value,
          keyboardType: TextInputType.emailAddress,
          onChanged: (String value) => controller.leadEmail.value = value,
          decoration: const InputDecoration(
            labelText: 'E-mail',
            prefixIcon: Icon(Icons.alternate_email_rounded),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          initialValue: controller.productInterest.value,
          onChanged: (String value) => controller.productInterest.value = value,
          decoration: const InputDecoration(
            labelText: 'Produto de interesse',
            prefixIcon: Icon(Icons.inventory_2_outlined),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          initialValue: controller.additionalContext.value,
          minLines: 3,
          maxLines: 5,
          maxLength: 2000,
          onChanged: (String value) =>
              controller.additionalContext.value = value,
          decoration: const InputDecoration(
            labelText: 'Contexto adicional',
            hintText: 'Ex.: pediu proposta e precisa decidir até sexta-feira.',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );

    if (compact) {
      return Card(
        child: ExpansionTile(
          leading: const Icon(Icons.badge_outlined, color: AppColors.primary),
          title: const Text(
            'Contexto do lead',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            controller.leadName.value.trim().isEmpty
                ? 'Preencha antes de testar'
                : controller.leadName.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          children: <Widget>[
            SizedBox(
              height: 260,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: form,
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: SingleChildScrollView(child: form),
      ),
    );
  }
}

class _AgentReadiness extends SignalWidget {
  const _AgentReadiness({required this.settings});

  final AgentSettingsController settings;

  @override
  Widget build(BuildContext context) {
    final configured = settings.agent.value != null;
    final color = configured ? AppColors.accent : AppColors.warning;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            configured
                ? Icons.check_circle_outline_rounded
                : Icons.warning_amber_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              configured
                  ? 'O teste usará a última configuração salva no servidor.'
                  : 'Salve a configuração do agente antes de executar o primeiro teste.',
              style: const TextStyle(fontSize: 11, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _SandboxChat extends StatelessWidget {
  const _SandboxChat({
    required this.entries,
    required this.messageController,
    required this.scrollController,
    required this.isSending,
    required this.errorMessage,
    required this.correlationId,
    required this.usage,
    required this.onSend,
    required this.onClear,
    required this.onDismissError,
  });

  final List<AgentSandboxEntry> entries;
  final TextEditingController messageController;
  final ScrollController scrollController;
  final bool isSending;
  final String? errorMessage;
  final String? correlationId;
  final Map<String, dynamic>? usage;
  final VoidCallback onSend;
  final VoidCallback onClear;
  final VoidCallback onDismissError;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 37,
                  height: 37,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.science_outlined,
                    color: Color(0xFF7C3AED),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Sandbox de atendimento',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Nenhuma mensagem será enviada para canais externos',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                if (usage != null) _UsageBadge(usage: usage!),
                IconButton(
                  tooltip: 'Limpar teste',
                  onPressed: entries.isEmpty ? null : onClear,
                  icon: const Icon(Icons.delete_sweep_outlined),
                ),
              ],
            ),
          ),
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Stack(
                children: <Widget>[
                  FormErrorBanner(
                    message: errorMessage!,
                    correlationId: correlationId,
                  ),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: IconButton(
                      tooltip: 'Fechar aviso',
                      onPressed: onDismissError,
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: entries.isEmpty
                ? const _EmptySandbox()
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
                    itemCount: entries.length,
                    itemBuilder: (BuildContext context, int index) {
                      return _SandboxMessage(entry: entries[index]);
                    },
                  ),
          ),
          Container(
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
                    controller: messageController,
                    enabled: !isSending,
                    minLines: 1,
                    maxLines: 5,
                    maxLength: 4000,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Escreva como se fosse o lead…',
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
                      backgroundColor: const Color(0xFF7C3AED),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    onPressed: isSending ? null : onSend,
                    child: isSending
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_awesome_rounded),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SandboxMessage extends StatelessWidget {
  const _SandboxMessage({required this.entry});

  final AgentSandboxEntry entry;

  @override
  Widget build(BuildContext context) {
    final isUser = entry.role == 'user';
    final reply = entry.reply;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 680),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : const Color(0xFFF3EEFF),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: Radius.circular(isUser ? 15 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 15),
          ),
          border: isUser ? null : Border.all(color: const Color(0xFFDFD2FF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  isUser
                      ? Icons.person_outline_rounded
                      : Icons.auto_awesome_rounded,
                  size: 14,
                  color: isUser ? Colors.white70 : const Color(0xFF7C3AED),
                ),
                const SizedBox(width: 5),
                Text(
                  isUser ? 'Lead de teste' : 'Resposta da IA',
                  style: TextStyle(
                    color: isUser ? Colors.white70 : const Color(0xFF6D28D9),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SelectableText(
              entry.content,
              style: TextStyle(
                color: isUser ? Colors.white : AppColors.ink,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              DateFormat('HH:mm').format(entry.createdAt),
              style: TextStyle(
                color: isUser ? Colors.white60 : AppColors.textSecondary,
                fontSize: 9,
              ),
            ),
            if (reply != null) ...<Widget>[
              const SizedBox(height: 11),
              _ResponseDiagnostics(reply: reply),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResponseDiagnostics extends StatelessWidget {
  const _ResponseDiagnostics({required this.reply});

  final AgentTestReplyModel reply;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFDFD2FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'DIAGNÓSTICO DA RESPOSTA',
            style: TextStyle(
              color: Color(0xFF6D28D9),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
          if (reply.productConsulted?.trim().isNotEmpty == true) ...<Widget>[
            const SizedBox(height: 8),
            _DiagnosticLine(
              icon: Icons.inventory_2_outlined,
              label: 'Produto consultado',
              value: reply.productConsulted!,
            ),
          ],
          if (reply.suggestedAction?.trim().isNotEmpty == true) ...<Widget>[
            const SizedBox(height: 7),
            _DiagnosticLine(
              icon: Icons.next_plan_outlined,
              label: 'Ação sugerida',
              value: reply.suggestedAction!,
            ),
          ],
          if (reply.rulesUsed.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            const Text(
              'Regras utilizadas',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: reply.rulesUsed
                  .map(
                    (String rule) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(rule, style: const TextStyle(fontSize: 9)),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          if (reply.shouldHandoff) ...<Widget>[
            const SizedBox(height: 8),
            const _WarningLine(
              message:
                  'A IA recomenda transferir esta conversa para um humano.',
              danger: false,
            ),
          ],
          for (final warning in reply.warnings) ...<Widget>[
            const SizedBox(height: 6),
            _WarningLine(message: warning, danger: true),
          ],
        ],
      ),
    );
  }
}

class _DiagnosticLine extends StatelessWidget {
  const _DiagnosticLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 7),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                TextSpan(text: value),
              ],
            ),
            style: const TextStyle(fontSize: 10, height: 1.35),
          ),
        ),
      ],
    );
  }
}

class _WarningLine extends StatelessWidget {
  const _WarningLine({required this.message, required this.danger});

  final String message;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.warning;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.warning_amber_rounded, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 9))),
        ],
      ),
    );
  }
}

class _UsageBadge extends StatelessWidget {
  const _UsageBadge({required this.usage});

  final Map<String, dynamic> usage;

  @override
  Widget build(BuildContext context) {
    final tokens = usage['totalTokens'];
    final latency = usage['latencyMs'];
    if (tokens == null && latency == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        <String>[
          if (tokens != null) '$tokens tokens',
          if (latency != null) '${latency}ms',
        ].join(' • '),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptySandbox extends StatelessWidget {
  const _EmptySandbox();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.forum_outlined,
                color: Color(0xFF7C3AED),
                size: 31,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'Simule uma conversa antes de publicar',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 390),
              child: Text(
                'Preencha o contexto do lead e envie uma mensagem. A resposta virá exclusivamente da API v1-agent-test-reply.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
