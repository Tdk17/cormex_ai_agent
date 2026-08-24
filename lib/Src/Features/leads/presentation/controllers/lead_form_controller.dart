import 'package:agente_vendas_saas/Src/Core/api/api_exception.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:agente_vendas_saas/Src/Features/leads/domain/lead_input.dart';
import 'package:agente_vendas_saas/Src/Features/leads/domain/leads_repository.dart';
import 'package:agente_vendas_saas/Src/Features/leads/presentation/controllers/leads_controller.dart';
import 'package:agente_vendas_saas/Src/Shared/models/lead_model.dart';
import 'package:signals/signals.dart';

class LeadFormController {
  LeadFormController(
    this._repository,
    this._authController,
    this._leadsController,
  );

  final LeadsRepository _repository;
  final AuthController _authController;
  final LeadsController _leadsController;

  final Signal<ScreenState> loadState = signal(ScreenState.initial);
  final Signal<bool> isSaving = signal(false);
  final Signal<String?> errorMessage = signal<String?>(null);
  final Signal<String?> correlationId = signal<String?>(null);

  Future<LeadModel?> load(String leadId) async {
    final cached = _leadsController.findById(leadId);
    if (cached != null) {
      loadState.value = ScreenState.success;
      return cached;
    }
    final workspaceId = _workspaceId;
    if (workspaceId == null) return null;
    loadState.value = ScreenState.loading;
    try {
      final lead = await _repository.get(workspaceId: workspaceId, leadId: leadId);
      loadState.value = ScreenState.success;
      return lead;
    } on ApiException catch (error) {
      _setLoadError(error);
    } on Object {
      errorMessage.value = 'Não foi possível carregar o lead para edição.';
      loadState.value = ScreenState.error;
    }
    return null;
  }

  Future<LeadModel?> save({String? leadId, required LeadInput input}) async {
    final validationMessage = validate(input);
    if (validationMessage != null) {
      errorMessage.value = validationMessage;
      return null;
    }
    final workspaceId = _workspaceId;
    if (workspaceId == null) {
      errorMessage.value = 'Selecione um workspace antes de salvar.';
      return null;
    }

    batch(() {
      isSaving.value = true;
      errorMessage.value = null;
      correlationId.value = null;
    });
    try {
      final result = leadId == null
          ? await _repository.create(workspaceId: workspaceId, input: input)
          : await _repository.update(
              workspaceId: workspaceId,
              leadId: leadId,
              input: input,
            );
      _leadsController.upsert(result);
      return result;
    } on ApiException catch (error) {
      batch(() {
        errorMessage.value = error.userMessage;
        correlationId.value = error.correlationId;
      });
    } on Object {
      errorMessage.value = 'Não foi possível salvar o lead.';
    } finally {
      isSaving.value = false;
    }
    return null;
  }

  String? validate(LeadInput input) {
    if (input.name.trim().length < 2) return 'Informe o nome do lead.';
    if ((input.phone?.trim().isEmpty ?? true) &&
        (input.email?.trim().isEmpty ?? true)) {
      return 'Informe pelo menos um telefone ou e-mail.';
    }
    final email = input.email?.trim();
    if (email != null &&
        email.isNotEmpty &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Informe um e-mail válido.';
    }
    return null;
  }

  String? get _workspaceId =>
      _authController.session.value?.selectedWorkspace?.id;

  void _setLoadError(ApiException error) {
    batch(() {
      errorMessage.value = error.userMessage;
      correlationId.value = error.correlationId;
      loadState.value = ScreenState.error;
    });
  }
}
