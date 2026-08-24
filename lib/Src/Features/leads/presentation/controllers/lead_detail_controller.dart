import 'package:agente_vendas_saas/Src/Core/api/api_exception.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:agente_vendas_saas/Src/Features/leads/domain/leads_repository.dart';
import 'package:agente_vendas_saas/Src/Shared/models/lead_model.dart';
import 'package:signals/signals.dart';

class LeadDetailController {
  LeadDetailController(this._repository, this._authController);

  final LeadsRepository _repository;
  final AuthController _authController;

  final Signal<ScreenState> state = signal(ScreenState.initial);
  final Signal<LeadModel?> lead = signal<LeadModel?>(null);
  final Signal<String?> errorMessage = signal<String?>(null);
  final Signal<String?> correlationId = signal<String?>(null);

  Future<void> load(String leadId, {LeadModel? cached}) async {
    final workspaceId = _authController.session.value?.selectedWorkspace?.id;
    if (workspaceId == null) {
      state.value = ScreenState.empty;
      return;
    }
    batch(() {
      lead.value = cached;
      state.value = ScreenState.loading;
      errorMessage.value = null;
    });
    try {
      final result = await _repository.get(workspaceId: workspaceId, leadId: leadId);
      batch(() {
        lead.value = result;
        state.value = ScreenState.success;
      });
    } on ApiException catch (error) {
      batch(() {
        errorMessage.value = error.userMessage;
        correlationId.value = error.correlationId;
        state.value = ScreenState.error;
      });
    } on Object {
      batch(() {
        errorMessage.value = 'Não foi possível carregar o lead.';
        state.value = ScreenState.error;
      });
    }
  }
}
