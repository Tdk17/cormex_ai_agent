import 'package:signals/signals.dart';

import 'auth_controller.dart';

class LoginController {
  LoginController(this._authController);

  final AuthController _authController;

  final Signal<String> email = signal('');
  final Signal<String> password = signal('');
  final Signal<bool> obscurePassword = signal(true);
  final Signal<String?> errorMessage = signal<String?>(null);

  late final isLoading = computed(() => _authController.isLoading.value);
  late final isValid = computed(
    () => _isValidEmail(email.value) && password.value.length >= 8,
  );

  Future<bool> submit() async {
    if (!_isValidEmail(email.value)) {
      errorMessage.value = 'Informe um e-mail válido.';
      return false;
    }
    if (password.value.length < 8) {
      errorMessage.value = 'A senha deve ter pelo menos 8 caracteres.';
      return false;
    }
    errorMessage.value = null;
    final success = await _authController.signIn(
      email: email.value,
      password: password.value,
    );
    if (!success) errorMessage.value = _authController.errorMessage.value;
    return success;
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  static bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
  }
}
