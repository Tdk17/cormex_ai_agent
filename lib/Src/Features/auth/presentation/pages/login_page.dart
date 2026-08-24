import 'package:agente_vendas_saas/Src/Core/di/service_locator.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/login_controller.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/widgets/auth_layout.dart';
import 'package:agente_vendas_saas/Src/Shared/components/form_error_banner.dart';
import 'package:agente_vendas_saas/Src/Shared/components/primary_loading_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';

class LoginPage extends SignalWidget {
  const LoginPage({super.key});

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF4F7FB),
      prefixIcon: Icon(icon, color: const Color(0xFF475467)),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF06B6D4), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LoginController controller = sl<LoginController>();
    final AuthController authController = sl<AuthController>();
    final String? error = controller.errorMessage.value;

    return AuthLayout(
      title: 'Bem-vindo de volta',
      subtitle:
          'Acesse seu painel e coloque sua operação comercial em movimento.',
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (error != null) ...<Widget>[
              FormErrorBanner(
                message: error,
                correlationId: authController.correlationId.value,
              ),
              const SizedBox(height: 18),
            ],
            TextField(
              autofillHints: const <String>[AutofillHints.email],
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              onChanged: (String value) {
                controller.email.value = value;
              },
              decoration: _inputDecoration(
                label: 'E-mail',
                hint: 'voce@empresa.com',
                icon: Icons.alternate_email_rounded,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              autofillHints: const <String>[AutofillHints.password],
              obscureText: controller.obscurePassword.value,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (String value) {
                controller.password.value = value;
              },
              onSubmitted: (_) => controller.submit(),
              decoration: _inputDecoration(
                label: 'Senha',
                hint: 'Mínimo de 8 caracteres',
                icon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  tooltip: controller.obscurePassword.value
                      ? 'Mostrar senha'
                      : 'Ocultar senha',
                  onPressed: controller.togglePasswordVisibility,
                  icon: Icon(
                    controller.obscurePassword.value
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  context.go('/forgot-password');
                },
                child: const Text('Esqueci minha senha'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: PrimaryLoadingButton(
                label: 'Entrar no CormeX',
                icon: Icons.arrow_forward_rounded,
                isLoading: controller.isLoading.value,
                onPressed: controller.submit,
              ),
            ),
            const SizedBox(height: 26),
            Row(
              children: <Widget>[
                const Expanded(child: Divider(color: Color(0xFFE4E7EC))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'NOVO POR AQUI?',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: Color(0xFFE4E7EC))),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  context.go('/register');
                },
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Criar minha conta'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
