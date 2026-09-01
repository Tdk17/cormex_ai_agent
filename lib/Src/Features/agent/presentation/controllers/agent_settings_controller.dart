import 'dart:async';

import 'package:agente_vendas_saas/Src/Core/api/api_exception.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/agent/domain/agent_configuration_input.dart';
import 'package:agente_vendas_saas/Src/Features/agent/domain/agent_constants.dart';
import 'package:agente_vendas_saas/Src/Features/agent/domain/agent_repository.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:agente_vendas_saas/Src/Shared/models/agent_models.dart';
import 'package:signals/signals.dart';

class AgentSettingsController {
  AgentSettingsController(this._repository, this._authController) {
    _disposeWorkspaceEffect = effect(() {
      final workspaceId = _workspaceId;
      if (_observedWorkspaceId == workspaceId) return;
      _observedWorkspaceId = workspaceId;
      _lastLoadedAgent = null;
      batch(() {
        agent.value = null;
        state.value = ScreenState.initial;
        errorMessage.value = null;
        successMessage.value = null;
      });
      _hydrate(null);
      if (workspaceId != null) unawaited(load(force: true));
    });
  }

  final AgentRepository _repository;
  final AuthController _authController;
  String? _observedWorkspaceId;
  SalesAgentModel? _lastLoadedAgent;
  int _formRevisionCounter = 0;
  late final void Function() _disposeWorkspaceEffect;

  final Signal<ScreenState> state = signal(ScreenState.initial);
  final Signal<SalesAgentModel?> agent = signal<SalesAgentModel?>(null);
  final Signal<bool> isSaving = signal(false);
  final Signal<String?> errorMessage = signal<String?>(null);
  final Signal<String?> successMessage = signal<String?>(null);
  final Signal<String?> correlationId = signal<String?>(null);
  final Signal<int> formRevision = signal(0);

  final Signal<String> name = signal('');
  final Signal<String> objective = signal('');
  final Signal<String> persona = signal('');
  final Signal<String> tone = signal(AgentTones.consultive);
  final Signal<String> mode = signal(AgentModes.assist);
  final Signal<String> productOffer = signal('');
  final Signal<String> initialMessage = signal('');
  final Signal<bool> isActive = signal(false);
  final Signal<List<String>> rules = signal<List<String>>(const <String>[]);
  final Signal<List<String>> qualificationQuestions =
      signal<List<String>>(const <String>[]);

  final Signal<bool> scheduleEnabled = signal(false);
  final Signal<String> scheduleTimezone = signal('America/Sao_Paulo');
  final Signal<List<int>> scheduleDays =
      signal<List<int>>(const <int>[1, 2, 3, 4, 5]);
  final Signal<String> scheduleStartTime = signal('08:00');
  final Signal<String> scheduleEndTime = signal('18:00');

  final Signal<int> maxResponseCharacters = signal(700);
  final Signal<int> maxAttemptsBeforeHandoff = signal(3);
  final Signal<bool> askForName = signal(true);
  final Signal<bool> askForPhone = signal(true);
  final Signal<bool> allowPricePresentation = signal(true);
  final Signal<bool> allowFollowUp = signal(true);
  final Signal<int> followUpDelayMinutes = signal(1440);
  final Signal<bool> handoffOnRequest = signal(true);

  Future<void> load({bool force = false}) async {
    if (!force && state.value == ScreenState.loading) return;
    final workspaceId = _workspaceId;
    if (workspaceId == null) {
      state.value = ScreenState.empty;
      return;
    }
    batch(() {
      state.value = ScreenState.loading;
      errorMessage.value = null;
      successMessage.value = null;
      correlationId.value = null;
    });
    try {
      final result = await _repository.get(workspaceId: workspaceId);
      _lastLoadedAgent = result.agent;
      _hydrate(result.agent);
      batch(() {
        agent.value = result.agent;
        correlationId.value = result.correlationId;
        state.value =
            result.agent == null ? ScreenState.empty : ScreenState.success;
      });
    } on ApiException catch (error) {
      _setError(error.userMessage, error.correlationId);
    } on Object {
      _setError('Não foi possível carregar o agente de IA.', null);
    }
  }

  Future<bool> save() async {
    if (isSaving.value) return false;
    final workspaceId = _workspaceId;
    if (workspaceId == null) return false;
    final validationError = validate();
    if (validationError != null) {
      errorMessage.value = validationError;
      successMessage.value = null;
      return false;
    }

    batch(() {
      isSaving.value = true;
      errorMessage.value = null;
      successMessage.value = null;
      correlationId.value = null;
    });
    try {
      final result = await _repository.update(
        workspaceId: workspaceId,
        input: AgentConfigurationInput(
          name: name.value,
          objective: objective.value,
          persona: persona.value,
          tone: tone.value,
          mode: mode.value,
          productOffer: productOffer.value,
          initialMessage: initialMessage.value,
          isActive: isActive.value,
          rules: rules.value,
          qualificationQuestions: qualificationQuestions.value,
          schedule: AgentScheduleModel(
            enabled: scheduleEnabled.value,
            timezone: scheduleTimezone.value,
            daysOfWeek: scheduleDays.value,
            startTime: scheduleStartTime.value,
            endTime: scheduleEndTime.value,
          ),
          policies: AgentPoliciesModel(
            maxResponseCharacters: maxResponseCharacters.value,
            maxAttemptsBeforeHandoff: maxAttemptsBeforeHandoff.value,
            askForName: askForName.value,
            askForPhone: askForPhone.value,
            allowPricePresentation: allowPricePresentation.value,
            allowFollowUp: allowFollowUp.value,
            followUpDelayMinutes: followUpDelayMinutes.value,
            handoffOnRequest: handoffOnRequest.value,
          ),
          expectedVersion: _lastLoadedAgent?.version,
        ),
      );
      _lastLoadedAgent = result.agent;
      _hydrate(result.agent);
      batch(() {
        agent.value = result.agent;
        state.value = ScreenState.success;
        correlationId.value = result.correlationId;
        successMessage.value = 'Configurações salvas com sucesso.';
      });
      return true;
    } on ApiException catch (error) {
      batch(() {
        errorMessage.value = error.code == 'CONFLICT'
            ? 'A configuração foi alterada em outra sessão. Atualize antes de salvar novamente.'
            : error.userMessage;
        correlationId.value = error.correlationId;
      });
      return false;
    } on Object {
      errorMessage.value = 'Não foi possível salvar as configurações.';
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  String? validate() {
    if (name.value.trim().length < 2 || name.value.trim().length > 80) {
      return 'O nome do agente deve ter entre 2 e 80 caracteres.';
    }
    if (objective.value.trim().length < 12 ||
        objective.value.trim().length > 1000) {
      return 'Descreva o objetivo comercial com 12 a 1.000 caracteres.';
    }
    if (persona.value.trim().length < 12 ||
        persona.value.trim().length > 1500) {
      return 'Descreva a persona do agente com 12 a 1.500 caracteres.';
    }
    if (!AgentTones.values.contains(tone.value)) {
      return 'Selecione um tom de voz válido.';
    }
    if (!AgentModes.values.contains(mode.value)) {
      return 'Selecione um modo de operação válido.';
    }
    if (productOffer.value.trim().length < 3 ||
        productOffer.value.trim().length > 1500) {
      return 'Informe o produto ou a oferta principal.';
    }
    if (initialMessage.value.trim().length < 5 ||
        initialMessage.value.trim().length > 1000) {
      return 'A mensagem inicial deve ter entre 5 e 1.000 caracteres.';
    }
    if (rules.value.isEmpty ||
        rules.value.any(
          (String item) => item.trim().length < 3 || item.length > 500,
        )) {
      return 'Adicione pelo menos uma regra válida para o agente.';
    }
    if (qualificationQuestions.value.isEmpty ||
        qualificationQuestions.value.any(
          (String item) => item.trim().length < 3 || item.length > 300,
        )) {
      return 'Adicione pelo menos uma pergunta de qualificação.';
    }
    if (scheduleEnabled.value && scheduleDays.value.isEmpty) {
      return 'Selecione pelo menos um dia de atendimento.';
    }
    if (!_validTime(scheduleStartTime.value) ||
        !_validTime(scheduleEndTime.value) ||
        scheduleStartTime.value == scheduleEndTime.value) {
      return 'Informe um horário de atendimento válido.';
    }
    if (maxResponseCharacters.value < 100 ||
        maxResponseCharacters.value > 4000) {
      return 'O limite da resposta deve ficar entre 100 e 4.000 caracteres.';
    }
    if (maxAttemptsBeforeHandoff.value < 1 ||
        maxAttemptsBeforeHandoff.value > 10) {
      return 'O limite de tentativas deve ficar entre 1 e 10.';
    }
    if (allowFollowUp.value &&
        (followUpDelayMinutes.value < 5 ||
            followUpDelayMinutes.value > 10080)) {
      return 'O atraso do follow-up deve ficar entre 5 minutos e 7 dias.';
    }
    return null;
  }

  void addRule(String value) => _addToList(rules, value, 500);

  void removeRule(int index) => _removeFromList(rules, index);

  void addQualificationQuestion(String value) =>
      _addToList(qualificationQuestions, value, 300);

  void removeQualificationQuestion(int index) =>
      _removeFromList(qualificationQuestions, index);

  void toggleScheduleDay(int day) {
    final next = <int>[...scheduleDays.value];
    next.contains(day) ? next.remove(day) : next.add(day);
    next.sort();
    scheduleDays.value = next;
  }

  void resetToSaved() {
    _hydrate(_lastLoadedAgent);
    batch(() {
      errorMessage.value = null;
      successMessage.value = null;
    });
  }

  void clearFeedback() {
    batch(() {
      errorMessage.value = null;
      successMessage.value = null;
    });
  }

  void dispose() => _disposeWorkspaceEffect();

  void _hydrate(SalesAgentModel? value) {
    final workspaceTimezone = _authController
            .session.value?.selectedWorkspace?.timezone ??
        'America/Sao_Paulo';
    batch(() {
      name.value = value?.name ?? '';
      objective.value = value?.objective ?? '';
      persona.value = value?.persona ?? '';
      tone.value = AgentTones.values.contains(value?.tone)
          ? value!.tone
          : AgentTones.consultive;
      mode.value = AgentModes.values.contains(value?.mode)
          ? value!.mode
          : AgentModes.assist;
      productOffer.value = value?.productOffer ?? '';
      initialMessage.value = value?.initialMessage ?? '';
      isActive.value = value?.isActive ?? false;
      rules.value = value?.rules ?? const <String>[];
      qualificationQuestions.value =
          value?.qualificationQuestions ?? const <String>[];
      scheduleEnabled.value = value?.schedule.enabled ?? false;
      scheduleTimezone.value = value?.schedule.timezone ?? workspaceTimezone;
      scheduleDays.value =
          value?.schedule.daysOfWeek ?? const <int>[1, 2, 3, 4, 5];
      scheduleStartTime.value = value?.schedule.startTime ?? '08:00';
      scheduleEndTime.value = value?.schedule.endTime ?? '18:00';
      maxResponseCharacters.value =
          value?.policies.maxResponseCharacters ?? 700;
      maxAttemptsBeforeHandoff.value =
          value?.policies.maxAttemptsBeforeHandoff ?? 3;
      askForName.value = value?.policies.askForName ?? true;
      askForPhone.value = value?.policies.askForPhone ?? true;
      allowPricePresentation.value =
          value?.policies.allowPricePresentation ?? true;
      allowFollowUp.value = value?.policies.allowFollowUp ?? true;
      followUpDelayMinutes.value =
          value?.policies.followUpDelayMinutes ?? 1440;
      handoffOnRequest.value = value?.policies.handoffOnRequest ?? true;
      formRevision.value = ++_formRevisionCounter;
    });
  }

  void _addToList(Signal<List<String>> target, String value, int maxLength) {
    final normalized = value.trim();
    if (normalized.length < 3 || normalized.length > maxLength) return;
    if (target.value.any(
      (String item) => item.toLowerCase() == normalized.toLowerCase(),
    )) {
      return;
    }
    target.value = <String>[...target.value, normalized];
  }

  void _removeFromList(Signal<List<String>> target, int index) {
    if (index < 0 || index >= target.value.length) return;
    final next = <String>[...target.value]..removeAt(index);
    target.value = next;
  }

  bool _validTime(String value) {
    final match = RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$').firstMatch(value);
    return match != null;
  }

  String? get _workspaceId =>
      _authController.session.value?.selectedWorkspace?.id;

  void _setError(String message, String? requestCorrelationId) {
    batch(() {
      errorMessage.value = message;
      correlationId.value = requestCorrelationId;
      state.value = ScreenState.error;
    });
  }
}
