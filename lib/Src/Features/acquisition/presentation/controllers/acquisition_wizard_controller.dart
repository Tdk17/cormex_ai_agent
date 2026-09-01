import 'dart:async';

import 'package:agente_vendas_saas/Src/Core/api/api_exception.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/acquisition/domain/acquisition_campaign_input.dart';
import 'package:agente_vendas_saas/Src/Features/acquisition/domain/acquisition_repository.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:agente_vendas_saas/Src/Shared/models/acquisition_models.dart';
import 'package:signals/signals.dart';

class AcquisitionWizardController {
  AcquisitionWizardController(this._repository, this._authController);

  final AcquisitionRepository _repository;
  final AuthController _authController;
  String? _pendingSaveRequestId;
  String? _pendingPublishRequestId;
  String? _pendingAiRequestId;
  int _revision = 0;

  final Signal<ScreenState> state = signal(ScreenState.initial);
  final Signal<AcquisitionCampaignModel?> campaign =
      signal<AcquisitionCampaignModel?>(null);
  final Signal<int> currentStep = signal(0);
  final Signal<int> formRevision = signal(0);
  final Signal<bool> isSaving = signal(false);
  final Signal<bool> isPublishing = signal(false);
  final Signal<bool> isGenerating = signal(false);
  final Signal<String?> errorMessage = signal<String?>(null);
  final Signal<String?> successMessage = signal<String?>(null);
  final Signal<String?> correlationId = signal<String?>(null);
  final Signal<List<String>> aiWarnings = signal<List<String>>(<String>[]);
  final Signal<String?> aiRationale = signal<String?>(null);

  final Signal<String> name = signal('');
  final Signal<String> productName = signal('');
  final Signal<String> productDescription = signal('');
  final Signal<String> offer = signal('');
  final Signal<String> productUrl = signal('');
  final Signal<String> mediaUrlsText = signal('');
  final Signal<String> objective = signal('leads');
  final Signal<List<String>> channels = signal<List<String>>(<String>['meta']);
  final Signal<String> locationsText = signal('');
  final Signal<int> ageMin = signal(18);
  final Signal<int> ageMax = signal(65);
  final Signal<String> interestsText = signal('');
  final Signal<bool> broadAudience = signal(true);
  final Signal<String> budgetType = signal('daily');
  final Signal<double> budgetAmount = signal(50);
  final Signal<DateTime?> startAt = signal<DateTime?>(null);
  final Signal<DateTime?> endAt = signal<DateTime?>(null);
  final Signal<String> headline = signal('');
  final Signal<String> primaryText = signal('');
  final Signal<String> description = signal('');
  final Signal<String> callToAction = signal('LEARN_MORE');
  final Signal<String> destinationType = signal('whatsapp');
  final Signal<String> destinationUrl = signal('');
  final Signal<List<String>> captureFields = signal<List<String>>(<String>[
    'name',
    'phone',
  ]);
  final Signal<String> consentText = signal('');
  final Signal<String> initialMessage = signal('');
  final Signal<String> qualificationQuestionsText = signal('');
  final Signal<String> pipelineStageId = signal('new_lead');
  final Signal<String> tagsText = signal('');
  final Signal<bool> onlyRegisterLead = signal(false);

  Future<void> initialize(String? campaignId) async {
    if (campaignId == null) {
      state.value = ScreenState.success;
      return;
    }
    if (state.value == ScreenState.loading) return;
    final workspaceId = _workspaceId;
    if (workspaceId == null) {
      state.value = ScreenState.empty;
      return;
    }
    batch(() {
      state.value = ScreenState.loading;
      errorMessage.value = null;
    });
    try {
      final result = await _repository.getCampaign(
        workspaceId: workspaceId,
        campaignId: campaignId,
      );
      if (_workspaceId != workspaceId) return;
      campaign.value = result;
      _hydrate(result);
      state.value = ScreenState.success;
    } on ApiException catch (error) {
      _setError(error.userMessage, error.correlationId, asPageError: true);
    } on Object {
      _setError(
        'Não foi possível carregar o rascunho.',
        null,
        asPageError: true,
      );
    }
  }

  void setChannels(String value, bool selected) {
    final next = <String>[...channels.value];
    selected ? next.add(value) : next.remove(value);
    channels.value = next.toSet().toList(growable: false);
  }

  void setCaptureField(String value, bool selected) {
    final next = <String>[...captureFields.value];
    selected ? next.add(value) : next.remove(value);
    captureFields.value = next.toSet().toList(growable: false);
  }

  bool nextStep() {
    final error = validateStep(currentStep.value);
    if (error != null) {
      errorMessage.value = error;
      return false;
    }
    errorMessage.value = null;
    if (currentStep.value < 8) currentStep.value++;
    unawaited(saveDraft(silent: true));
    return true;
  }

  void previousStep() {
    errorMessage.value = null;
    if (currentStep.value > 0) currentStep.value--;
  }

  Future<bool> saveDraft({bool silent = false}) async {
    if (isSaving.value) return false;
    final workspaceId = _workspaceId;
    if (workspaceId == null) return false;
    if (name.value.trim().length < 3 || productName.value.trim().length < 2) {
      if (!silent) {
        errorMessage.value =
            'Informe o nome da campanha e o produto antes de salvar.';
      }
      return false;
    }
    batch(() {
      isSaving.value = true;
      errorMessage.value = null;
      if (!silent) successMessage.value = null;
    });
    _pendingSaveRequestId ??= _requestId('save');
    try {
      final result = await _repository.upsertCampaign(
        workspaceId: workspaceId,
        campaignId: campaign.value?.id,
        input: input,
        clientRequestId: _pendingSaveRequestId!,
      );
      if (_workspaceId != workspaceId) return false;
      _pendingSaveRequestId = null;
      batch(() {
        campaign.value = result.campaign;
        correlationId.value = result.correlationId;
        state.value = ScreenState.success;
        if (!silent) successMessage.value = 'Rascunho salvo.';
      });
      return true;
    } on ApiException catch (error) {
      _setError(
        error.code == 'CONFLICT'
            ? 'A campanha foi alterada em outra sessão. Atualize antes de salvar.'
            : error.userMessage,
        error.correlationId,
      );
      return false;
    } on Object {
      _setError('Não foi possível salvar o rascunho.', null);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> publish() async {
    if (isPublishing.value) return false;
    final validationError = validateAll();
    if (validationError != null) {
      errorMessage.value = validationError.message;
      currentStep.value = validationError.step;
      return false;
    }
    if (!await saveDraft(silent: true)) return false;
    final saved = campaign.value;
    final workspaceId = _workspaceId;
    if (saved == null || workspaceId == null) return false;
    batch(() {
      isPublishing.value = true;
      errorMessage.value = null;
      successMessage.value = null;
    });
    _pendingPublishRequestId ??= _requestId('publish');
    try {
      final result = await _repository.publishCampaign(
        workspaceId: workspaceId,
        campaignId: saved.id,
        expectedVersion: saved.version,
        clientRequestId: _pendingPublishRequestId!,
      );
      if (_workspaceId != workspaceId) return false;
      _pendingPublishRequestId = null;
      batch(() {
        campaign.value = result.campaign;
        correlationId.value = result.correlationId;
        successMessage.value = 'Campanha enviada para publicação.';
      });
      return true;
    } on ApiException catch (error) {
      _setError(
        error.code == 'CONFLICT'
            ? 'A campanha mudou antes da publicação. Atualize e revise novamente.'
            : error.userMessage,
        error.correlationId,
      );
      return false;
    } on Object {
      _setError('Não foi possível publicar a campanha.', null);
      return false;
    } finally {
      isPublishing.value = false;
    }
  }

  Future<bool> generateCreative() async {
    if (isGenerating.value) return false;
    if (productName.value.trim().isEmpty || objective.value.isEmpty) {
      errorMessage.value = 'Informe o produto e o objetivo antes de usar a IA.';
      return false;
    }
    final workspaceId = _workspaceId;
    if (workspaceId == null) return false;
    batch(() {
      isGenerating.value = true;
      errorMessage.value = null;
      successMessage.value = null;
      aiWarnings.value = const <String>[];
      aiRationale.value = null;
    });
    _pendingAiRequestId ??= _requestId('ai');
    try {
      final result = await _repository.suggestCreative(
        workspaceId: workspaceId,
        input: input,
        clientRequestId: _pendingAiRequestId!,
      );
      if (_workspaceId != workspaceId) return false;
      _pendingAiRequestId = null;
      batch(() {
        headline.value = result.headline;
        primaryText.value = result.primaryText;
        description.value = result.description;
        callToAction.value = result.callToAction;
        aiWarnings.value = result.warnings;
        aiRationale.value = result.rationale;
        correlationId.value = result.correlationId;
        formRevision.value = ++_revision;
        successMessage.value = 'Sugestão criada. Revise antes de continuar.';
      });
      return true;
    } on ApiException catch (error) {
      _setError(error.userMessage, error.correlationId);
      return false;
    } on Object {
      _setError('Não foi possível gerar o criativo com IA.', null);
      return false;
    } finally {
      isGenerating.value = false;
    }
  }

  AcquisitionCampaignInput get input => AcquisitionCampaignInput(
    name: name.value,
    productName: productName.value,
    productDescription: productDescription.value,
    offer: offer.value,
    productUrl: productUrl.value,
    mediaUrls: _lines(mediaUrlsText.value),
    objective: objective.value,
    channels: channels.value,
    locations: _lines(locationsText.value),
    ageMin: ageMin.value,
    ageMax: ageMax.value,
    interests: _lines(interestsText.value),
    broadAudience: broadAudience.value,
    budgetType: budgetType.value,
    budgetAmount: budgetAmount.value,
    startAt: startAt.value,
    endAt: endAt.value,
    headline: headline.value,
    primaryText: primaryText.value,
    description: description.value,
    callToAction: callToAction.value,
    destinationType: destinationType.value,
    destinationUrl: destinationUrl.value,
    captureFields: captureFields.value,
    consentText: consentText.value,
    initialMessage: initialMessage.value,
    qualificationQuestions: _lines(qualificationQuestionsText.value),
    pipelineStageId: pipelineStageId.value,
    tags: _lines(tagsText.value),
    onlyRegisterLead: onlyRegisterLead.value,
    expectedVersion: campaign.value?.version,
  );

  String? validateStep(int step) => switch (step) {
    0 when name.value.trim().length < 3 =>
      'O nome da campanha deve ter pelo menos 3 caracteres.',
    0 when productName.value.trim().length < 2 =>
      'Informe o produto ou serviço anunciado.',
    1 when objective.value.isEmpty => 'Selecione o objetivo da campanha.',
    2 when channels.value.isEmpty => 'Selecione pelo menos um canal.',
    3 when _lines(locationsText.value).isEmpty =>
      'Informe pelo menos uma localização.',
    3
        when ageMin.value < 18 ||
            ageMax.value > 65 ||
            ageMin.value > ageMax.value =>
      'Informe uma faixa etária válida entre 18 e 65 anos.',
    4 when budgetAmount.value <= 0 => 'Informe um orçamento maior que zero.',
    4 when startAt.value == null => 'Informe a data de início.',
    4 when endAt.value != null && endAt.value!.isBefore(startAt.value!) =>
      'A data final não pode ser anterior ao início.',
    5 when headline.value.trim().length < 3 =>
      'Informe ou gere um título para o anúncio.',
    5 when primaryText.value.trim().length < 10 =>
      'O texto principal deve ter pelo menos 10 caracteres.',
    6
        when destinationType.value != 'whatsapp' &&
            destinationUrl.value.trim().isEmpty =>
      'Informe o endereço de destino.',
    6 when destinationType.value == 'form' && captureFields.value.isEmpty =>
      'Selecione pelo menos um campo para o formulário.',
    7 when !onlyRegisterLead.value && initialMessage.value.trim().length < 5 =>
      'Informe a mensagem inicial da automação.',
    _ => null,
  };

  ({int step, String message})? validateAll() {
    for (var step = 0; step < 9; step++) {
      final error = validateStep(step);
      if (error != null) return (step: step, message: error);
    }
    return null;
  }

  void clearFeedback() {
    batch(() {
      errorMessage.value = null;
      successMessage.value = null;
    });
  }

  void _hydrate(AcquisitionCampaignModel value) {
    final data = value.input ?? const <String, dynamic>{};
    final audience = _map(data['audience']);
    final budget = _map(data['budget']);
    final creative = _map(data['creative']);
    final destination = _map(data['destination']);
    final automation = _map(data['automation']);
    batch(() {
      name.value = _text(data['name'], fallback: value.name);
      productName.value = _text(
        data['productName'],
        fallback: value.productName,
      );
      productDescription.value = _text(data['productDescription']);
      offer.value = _text(data['offer']);
      productUrl.value = _text(data['productUrl']);
      mediaUrlsText.value = _list(data['mediaUrls']).join('\n');
      objective.value = _text(
        data['objective'],
        fallback: value.objective.isEmpty ? 'leads' : value.objective,
      );
      channels.value = _list(data['channels']).isEmpty
          ? value.channels
          : _list(data['channels']);
      locationsText.value = _list(audience['locations']).join('\n');
      ageMin.value = (audience['ageMin'] as num?)?.toInt() ?? 18;
      ageMax.value = (audience['ageMax'] as num?)?.toInt() ?? 65;
      interestsText.value = _list(audience['interests']).join('\n');
      broadAudience.value = audience['broad'] as bool? ?? true;
      budgetType.value = _text(budget['type'], fallback: value.budgetType);
      budgetAmount.value =
          (budget['amount'] as num?)?.toDouble() ?? value.budgetAmount;
      startAt.value =
          DateTime.tryParse(data['startAt']?.toString() ?? '') ?? value.startAt;
      endAt.value =
          DateTime.tryParse(data['endAt']?.toString() ?? '') ?? value.endAt;
      headline.value = _text(creative['headline']);
      primaryText.value = _text(creative['primaryText']);
      description.value = _text(creative['description']);
      callToAction.value = _text(
        creative['callToAction'],
        fallback: 'LEARN_MORE',
      );
      destinationType.value = _text(destination['type'], fallback: 'whatsapp');
      destinationUrl.value = _text(destination['url']);
      captureFields.value = _list(destination['captureFields']).isEmpty
          ? <String>['name', 'phone']
          : _list(destination['captureFields']);
      consentText.value = _text(destination['consentText']);
      initialMessage.value = _text(automation['initialMessage']);
      qualificationQuestionsText.value = _list(
        automation['qualificationQuestions'],
      ).join('\n');
      pipelineStageId.value = _text(
        automation['pipelineStageId'],
        fallback: 'new_lead',
      );
      tagsText.value = _list(automation['tags']).join('\n');
      onlyRegisterLead.value = automation['onlyRegisterLead'] as bool? ?? false;
      formRevision.value = ++_revision;
    });
  }

  String? get _workspaceId =>
      _authController.session.value?.selectedWorkspace?.id;

  String _requestId(String operation) =>
      '$operation:${campaign.value?.id ?? _workspaceId}:${DateTime.now().microsecondsSinceEpoch}';

  void _setError(
    String message,
    String? requestCorrelationId, {
    bool asPageError = false,
  }) {
    batch(() {
      errorMessage.value = message;
      correlationId.value = requestCorrelationId;
      if (asPageError) state.value = ScreenState.error;
    });
  }

  static Map<String, dynamic> _map(dynamic raw) =>
      raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

  static List<String> _list(dynamic raw) => raw is List
      ? raw
            .map((dynamic item) => item.toString().trim())
            .where((String item) => item.isNotEmpty)
            .toList(growable: false)
      : const <String>[];

  static List<String> _lines(String value) => value
      .split(RegExp(r'[,\n]'))
      .map((String item) => item.trim())
      .where((String item) => item.isNotEmpty)
      .toSet()
      .toList(growable: false);

  static String _text(dynamic value, {String fallback = ''}) {
    final text = value?.toString() ?? '';
    return text.isEmpty ? fallback : text;
  }
}
