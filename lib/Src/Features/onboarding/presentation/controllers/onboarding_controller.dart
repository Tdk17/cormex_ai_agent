import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:signals/signals.dart';

class OnboardingController {
  OnboardingController(this._authController);

  final AuthController _authController;

  final Signal<int> currentStep = signal(0);
  final Signal<String> workspaceName = signal('');
  final Signal<String> companySegment = signal('');
  final Signal<String> timezone = signal('America/Sao_Paulo');
  final Signal<String> agentName = signal('Clara');
  final Signal<String> agentObjective = signal('');
  final Signal<String?> errorMessage = signal<String?>(null);

  late final isLoading = computed(() => _authController.isLoading.value);

  void reset() {
    batch(() {
      currentStep.value = 0;
      workspaceName.value = '';
      companySegment.value = '';
      timezone.value = 'America/Sao_Paulo';
      agentName.value = 'Clara';
      agentObjective.value = '';
      errorMessage.value = null;
    });
  }

  bool nextStep() {
    final error = _validateStep(currentStep.value);
    if (error != null) {
      errorMessage.value = error;
      return false;
    }
    errorMessage.value = null;
    if (currentStep.value < 2) currentStep.value++;
    return true;
  }

  void previousStep() {
    errorMessage.value = null;
    if (currentStep.value > 0) currentStep.value--;
  }

  Future<bool> finish() async {
    final error = _validateStep(2);
    if (error != null) {
      errorMessage.value = error;
      return false;
    }
    errorMessage.value = null;
    final success = await _authController.completeOnboarding(
      workspaceName: workspaceName.value,
      timezone: timezone.value,
      companySegment: companySegment.value,
      agentName: agentName.value,
      agentObjective: agentObjective.value,
    );
    if (!success) errorMessage.value = _authController.errorMessage.value;
    return success;
  }

  String? _validateStep(int step) => switch (step) {
        0 when workspaceName.value.trim().length < 3 =>
          'Informe o nome da empresa.',
        1 when companySegment.value.trim().isEmpty =>
          'Selecione ou informe o segmento da empresa.',
        2 when agentName.value.trim().length < 2 =>
          'Dê um nome ao agente de vendas.',
        2 when agentObjective.value.trim().length < 12 =>
          'Descreva o objetivo comercial com um pouco mais de detalhe.',
        _ => null,
      };
}
