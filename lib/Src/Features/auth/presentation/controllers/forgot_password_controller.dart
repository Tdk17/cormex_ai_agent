import 'package:agente_vendas_saas/Src/Core/api/api_exception.dart';
import 'package:agente_vendas_saas/Src/Features/auth/domain/auth_repository.dart';
import 'package:signals/signals.dart';

class ForgotPasswordController {
  ForgotPasswordController(this._repository);

  final AuthRepository _repository;

  final Signal<String> email = signal('');
  final Signal<bool> isLoading = signal(false);
  final Signal<String?> errorMessage = signal<String?>(null);
  final Signal<bool> emailSent = signal(false);

  Future<bool> submit() async {
    if (isLoading.value) return false;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.value.trim())) {
      errorMessage.value = 'Informe um e-mail válido.';
      return false;
    }
    batch(() {
      isLoading.value = true;
      errorMessage.value = null;
      emailSent.value = false;
    });
    try {
      await _repository.requestPasswordReset(email.value);
      emailSent.value = true;
      return true;
    } on ApiException catch (error) {
      errorMessage.value = error.userMessage;
      return false;
    } on Object {
      errorMessage.value = 'Não foi possível enviar o e-mail.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
