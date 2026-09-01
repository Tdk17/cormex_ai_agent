import 'package:signals/signals.dart';

import 'auth_controller.dart';

class CadastroController {
  CadastroController(this._authController);

  final AuthController _authController;

  final Signal<String> name = signal('');
  final Signal<String> email = signal('');
  final Signal<String> password = signal('');
  final Signal<String> confirmPassword = signal('');
  final Signal<bool> acceptedTerms = signal(false);
  final Signal<bool> obscurePassword = signal(true);
  final Signal<String?> errorMessage = signal<String?>(null);

  late final isLoading = computed(() => _authController.isLoading.value);
  late final isValid = computed(
    () => name.value.trim().length >= 3 &&
        _isValidEmail(email.value) &&
        password.value.length >= 8 &&
        password.value == confirmPassword.value &&
        acceptedTerms.value,
  );

  Future<bool> submit() async {
    final validationError = _validationError();
    if (validationError != null) {
      errorMessage.value = validationError;
      return false;
    }
    errorMessage.value = null;
    final success = await _authController.signUp(
      name: name.value,
      email: email.value,
      password: password.value,
    );
    if (success) {
      batch(() {
        name.value = '';
        email.value = '';
        password.value = '';
        confirmPassword.value = '';
        acceptedTerms.value = false;
        errorMessage.value = null;
      });
    } else {
      errorMessage.value = _authController.errorMessage.value;
    }
    return success;
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  String? _validationError() {
    if (name.value.trim().length < 3) return 'Informe seu nome completo.';
    if (!_isValidEmail(email.value)) return 'Informe um e-mail válido.';
    if (password.value.length < 8) {
      return 'A senha deve ter pelo menos 8 caracteres.';
    }
    if (password.value != confirmPassword.value) return 'As senhas não coincidem.';
    if (!acceptedTerms.value) return 'Aceite os termos para criar sua conta.';
    return null;
  }

  static bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
  }
}
