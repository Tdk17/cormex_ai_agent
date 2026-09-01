import 'dart:convert';

import 'package:agente_vendas_saas/Src/Core/api/api_exception.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/agent/domain/agent_repository.dart';
import 'package:agente_vendas_saas/Src/Features/agent/domain/agent_test_request.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:agente_vendas_saas/Src/Shared/models/agent_models.dart';
import 'package:signals/signals.dart';

class AgentTestController {
  AgentTestController(this._repository, this._authController) {
    _disposeWorkspaceEffect = effect(() {
      final workspaceId =
          _authController.session.value?.selectedWorkspace?.id;
      if (_observedWorkspaceId == workspaceId) return;
      _observedWorkspaceId = workspaceId;
      clearConversation();
      batch(() {
        leadName.value = '';
        leadCompany.value = '';
        leadPhone.value = '';
        leadEmail.value = '';
        productInterest.value = '';
        additionalContext.value = '';
      });
    });
  }

  final AgentRepository _repository;
  final AuthController _authController;
  String? _observedWorkspaceId;
  late final void Function() _disposeWorkspaceEffect;

  final Signal<ScreenState> state = signal(ScreenState.initial);
  final Signal<bool> isSending = signal(false);
  final Signal<List<AgentSandboxEntry>> messages =
      signal<List<AgentSandboxEntry>>(const <AgentSandboxEntry>[]);
  final Signal<String?> errorMessage = signal<String?>(null);
  final Signal<String?> correlationId = signal<String?>(null);
  final Signal<Map<String, dynamic>?> lastUsage =
      signal<Map<String, dynamic>?>(null);

  final Signal<String> leadName = signal('');
  final Signal<String> leadCompany = signal('');
  final Signal<String> leadPhone = signal('');
  final Signal<String> leadEmail = signal('');
  final Signal<String> productInterest = signal('');
  final Signal<String> additionalContext = signal('');

  String? _pendingFingerprint;
  String? _pendingRequestId;
  int _requestSequence = 0;

  Future<bool> send(String rawMessage) async {
    if (isSending.value) return false;
    final workspaceId =
        _authController.session.value?.selectedWorkspace?.id;
    final message = rawMessage.trim();
    if (workspaceId == null) return false;
    if (leadName.value.trim().length < 2) {
      errorMessage.value = 'Informe o nome do lead usado no teste.';
      return false;
    }
    if (message.isEmpty || message.length > 4000) {
      errorMessage.value =
          'A mensagem de teste deve ter entre 1 e 4.000 caracteres.';
      return false;
    }
    if (additionalContext.value.trim().length > 2000) {
      errorMessage.value =
          'O contexto adicional deve ter no máximo 2.000 caracteres.';
      return false;
    }

    final lead = <String, dynamic>{
      'name': leadName.value.trim(),
      if (leadCompany.value.trim().isNotEmpty)
        'company': leadCompany.value.trim(),
      if (leadPhone.value.trim().isNotEmpty) 'phone': leadPhone.value.trim(),
      if (leadEmail.value.trim().isNotEmpty) 'email': leadEmail.value.trim(),
    };
    final context = <String, dynamic>{
      if (productInterest.value.trim().isNotEmpty)
        'productInterest': productInterest.value.trim(),
      if (additionalContext.value.trim().isNotEmpty)
        'notes': additionalContext.value.trim(),
    };
    final history = messages.value
        .takeLast(20)
        .map(
          (AgentSandboxEntry item) => <String, String>{
            'role': item.role,
            'content': item.content,
          },
        )
        .toList(growable: false);
    final fingerprint = jsonEncode(<String, dynamic>{
      'lead': lead,
      'context': context,
      'history': history,
      'message': message,
    });
    final requestId = _pendingFingerprint == fingerprint &&
            _pendingRequestId != null
        ? _pendingRequestId!
        : 'agent_test_${DateTime.now().microsecondsSinceEpoch}_${_requestSequence++}';
    _pendingFingerprint = fingerprint;
    _pendingRequestId = requestId;

    batch(() {
      isSending.value = true;
      errorMessage.value = null;
      correlationId.value = null;
    });
    try {
      final result = await _repository.testReply(
        workspaceId: workspaceId,
        request: AgentTestRequest(
          message: message,
          lead: lead,
          context: context,
          history: history,
          clientRequestId: requestId,
        ),
      );
      final now = DateTime.now();
      batch(() {
        messages.value = <AgentSandboxEntry>[
          ...messages.value,
          AgentSandboxEntry(role: 'user', content: message, createdAt: now),
          AgentSandboxEntry(
            role: 'assistant',
            content: result.reply.content,
            createdAt: now,
            reply: result.reply,
          ),
        ];
        state.value = ScreenState.success;
        correlationId.value = result.correlationId;
        lastUsage.value = result.usage;
      });
      _pendingFingerprint = null;
      _pendingRequestId = null;
      return true;
    } on ApiException catch (error) {
      batch(() {
        errorMessage.value = error.userMessage;
        correlationId.value = error.correlationId;
        state.value = ScreenState.error;
      });
      return false;
    } on Object {
      batch(() {
        errorMessage.value = 'Não foi possível gerar a resposta de teste.';
        state.value = ScreenState.error;
      });
      return false;
    } finally {
      isSending.value = false;
    }
  }

  void clearConversation() {
    batch(() {
      messages.value = const <AgentSandboxEntry>[];
      state.value = ScreenState.initial;
      errorMessage.value = null;
      correlationId.value = null;
      lastUsage.value = null;
    });
    _pendingFingerprint = null;
    _pendingRequestId = null;
  }

  void clearError() => errorMessage.value = null;

  void dispose() => _disposeWorkspaceEffect();
}

class AgentSandboxEntry {
  const AgentSandboxEntry({
    required this.role,
    required this.content,
    required this.createdAt,
    this.reply,
  });

  final String role;
  final String content;
  final DateTime createdAt;
  final AgentTestReplyModel? reply;
}

extension _IterableTakeLast<T> on Iterable<T> {
  Iterable<T> takeLast(int count) {
    final items = toList(growable: false);
    return items.length <= count ? items : items.skip(items.length - count);
  }
}
