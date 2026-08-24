import 'package:agente_vendas_saas/Src/Core/api/api_exception.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:agente_vendas_saas/Src/Features/pipeline/domain/pipeline_repository.dart';
import 'package:agente_vendas_saas/Src/Features/pipeline/presentation/controllers/pipeline_controller.dart';
import 'package:agente_vendas_saas/Src/Shared/models/pipeline_models.dart';
import 'package:signals/signals.dart';

class OpportunityDetailController {
  OpportunityDetailController(
    this._repository,
    this._authController,
    this._pipelineController,
  );

  final PipelineRepository _repository;
  final AuthController _authController;
  final PipelineController _pipelineController;

  final Signal<ScreenState> state = signal(ScreenState.initial);
  final Signal<OpportunityModel?> opportunity = signal<OpportunityModel?>(null);
  final Signal<String?> errorMessage = signal<String?>(null);
  final Signal<String?> correlationId = signal<String?>(null);

  Future<void> load(String opportunityId) async {
    final workspaceId = _authController.session.value?.selectedWorkspace?.id;
    if (workspaceId == null) return;
    batch(() {
      opportunity.value = _pipelineController.findById(opportunityId);
      state.value = ScreenState.loading;
      errorMessage.value = null;
    });
    try {
      final result = await _repository.get(
        workspaceId: workspaceId,
        opportunityId: opportunityId,
      );
      batch(() {
        opportunity.value = result;
        state.value = ScreenState.success;
      });
      _pipelineController.upsert(result);
    } on ApiException catch (error) {
      batch(() {
        errorMessage.value = error.userMessage;
        correlationId.value = error.correlationId;
        state.value = ScreenState.error;
      });
    } on Object {
      batch(() {
        errorMessage.value = 'Não foi possível carregar a oportunidade.';
        state.value = ScreenState.error;
      });
    }
  }
}
