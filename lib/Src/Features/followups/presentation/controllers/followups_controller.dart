import 'dart:async';

import 'package:agente_vendas_saas/Src/Core/api/api_exception.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:agente_vendas_saas/Src/Features/followups/domain/followup_rule_input.dart';
import 'package:agente_vendas_saas/Src/Features/followups/domain/followups_repository.dart';
import 'package:agente_vendas_saas/Src/Shared/models/followup_models.dart';
import 'package:signals/signals.dart';

class FollowUpsController {
  FollowUpsController(this._repository, this._authController) {
    _disposeWorkspaceEffect = effect(() {
      final workspaceId = _workspaceId;
      if (_observedWorkspaceId == workspaceId) return;
      _observedWorkspaceId = workspaceId;
      batch(() {
        rules.value = const <FollowUpRuleModel>[];
        state.value = ScreenState.initial;
        nextCursor.value = null;
      });
      if (workspaceId != null) unawaited(load(force: true));
    });
  }

  final FollowUpsRepository _repository;
  final AuthController _authController;
  late final void Function() _disposeWorkspaceEffect;
  Timer? _searchDebounce;
  String? _observedWorkspaceId;

  final Signal<ScreenState> state = signal(ScreenState.initial);
  final Signal<List<FollowUpRuleModel>> rules =
      signal<List<FollowUpRuleModel>>(const <FollowUpRuleModel>[]);
  final Signal<String> searchText = signal('');
  final Signal<String?> nextCursor = signal<String?>(null);
  final Signal<bool> isMutating = signal(false);
  final Signal<String?> errorMessage = signal<String?>(null);
  final Signal<String?> successMessage = signal<String?>(null);
  final Signal<String?> correlationId = signal<String?>(null);

  Future<void> load({bool force = false}) async {
    if (!force && state.value == ScreenState.loading) return;
    final workspaceId = _workspaceId;
    if (workspaceId == null) return;
    batch(() {
      state.value = ScreenState.loading;
      errorMessage.value = null;
    });
    try {
      final page = await _repository.list(
        workspaceId: workspaceId,
        search: searchText.value,
      );
      if (_workspaceId != workspaceId) return;
      batch(() {
        rules.value = page.items;
        nextCursor.value = page.nextCursor;
        correlationId.value = page.correlationId;
        state.value = page.items.isEmpty ? ScreenState.empty : ScreenState.success;
      });
    } on ApiException catch (error) {
      _setError(error.userMessage, error.correlationId, pageError: true);
    } on Object {
      _setError('Não foi possível carregar os follow-ups.', null, pageError: true);
    }
  }

  void search(String value) {
    searchText.value = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 450),
      () => load(force: true),
    );
  }

  Future<bool> save(FollowUpRuleInput input, {String? followupId}) async {
    final workspaceId = _workspaceId;
    if (workspaceId == null || isMutating.value) return false;
    batch(() {
      isMutating.value = true;
      errorMessage.value = null;
      successMessage.value = null;
    });
    try {
      final rule = await _repository.upsert(
        workspaceId: workspaceId,
        input: input,
        followupId: followupId,
        clientRequestId: 'followup_${DateTime.now().microsecondsSinceEpoch}',
      );
      _upsert(rule);
      successMessage.value = followupId == null
          ? 'Follow-up criado.'
          : 'Follow-up atualizado.';
      return true;
    } on ApiException catch (error) {
      _setError(
        error.code == 'CONFLICT'
            ? 'Esta regra foi alterada em outra sessão. Atualize e tente novamente.'
            : error.userMessage,
        error.correlationId,
      );
      return false;
    } on Object {
      errorMessage.value = 'Não foi possível salvar o follow-up.';
      return false;
    } finally {
      isMutating.value = false;
    }
  }

  Future<bool> toggle(FollowUpRuleModel rule, bool active) {
    return save(
      FollowUpRuleInput(
        name: rule.name,
        delayMinutes: rule.delayMinutes,
        condition: rule.condition,
        active: active,
        channel: rule.channel,
        message: rule.message,
        maxAttempts: rule.maxAttempts,
        stopOnReply: rule.stopOnReply,
        stopOnLost: rule.stopOnLost,
        expectedVersion: rule.version,
      ),
      followupId: rule.id,
    );
  }

  void clearFeedback() {
    errorMessage.value = null;
    successMessage.value = null;
  }

  void _upsert(FollowUpRuleModel rule) {
    final items = <FollowUpRuleModel>[...rules.value];
    final index = items.indexWhere((FollowUpRuleModel item) => item.id == rule.id);
    if (index < 0) {
      items.insert(0, rule);
    } else {
      items[index] = rule;
    }
    rules.value = items;
    state.value = ScreenState.success;
  }

  String? get _workspaceId =>
      _authController.session.value?.selectedWorkspace?.id;

  void _setError(
    String message,
    String? requestCorrelationId, {
    bool pageError = false,
  }) {
    batch(() {
      errorMessage.value = message;
      correlationId.value = requestCorrelationId;
      if (pageError) state.value = ScreenState.error;
    });
  }

  void dispose() {
    _searchDebounce?.cancel();
    _disposeWorkspaceEffect();
  }
}
