import 'package:agente_vendas_saas/Src/Core/api/api_exception.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/acquisition/domain/acquisition_repository.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:agente_vendas_saas/Src/Shared/models/acquisition_models.dart';
import 'package:signals/signals.dart';

class AcquisitionCampaignDetailController {
  AcquisitionCampaignDetailController(this._repository, this._authController);

  final AcquisitionRepository _repository;
  final AuthController _authController;

  final Signal<ScreenState> state = signal(ScreenState.initial);
  final Signal<AcquisitionCampaignModel?> campaign =
      signal<AcquisitionCampaignModel?>(null);
  final Signal<String?> errorMessage = signal<String?>(null);
  final Signal<String?> correlationId = signal<String?>(null);

  Future<void> load(String campaignId) async {
    if (state.value == ScreenState.loading) return;
    final workspaceId = _authController.session.value?.selectedWorkspace?.id;
    if (workspaceId == null) {
      state.value = ScreenState.empty;
      return;
    }
    batch(() {
      state.value = ScreenState.loading;
      errorMessage.value = null;
      correlationId.value = null;
    });
    try {
      final result = await _repository.getCampaign(
        workspaceId: workspaceId,
        campaignId: campaignId,
      );
      if (_authController.session.value?.selectedWorkspace?.id != workspaceId) {
        return;
      }
      batch(() {
        campaign.value = result;
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
        errorMessage.value = 'Não foi possível carregar a campanha.';
        state.value = ScreenState.error;
      });
    }
  }
}
