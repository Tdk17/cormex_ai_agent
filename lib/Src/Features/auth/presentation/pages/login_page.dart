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

  @override
  Widget build(BuildContext context) {
    final controller = sl<LoginController>();
    final authController = sl<AuthController>();
    final error = controller.errorMessage.value;

    return AuthLayout(
      title: 'Bem-vindo de volta',
      subtitle: 'Entre para continuar sua operação comercial.',
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
              onChanged: (String value) => controller.email.value = value,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                hintText: 'voce@empresa.com',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              autofillHints: const <String>[AutofillHints.password],
              obscureText: controller.obscurePassword.value,
              textInputAction: TextInputAction.done,
              onChanged: (String value) => controller.password.value = value,
              onSubmitted: (_) => controller.submit(),
              decoration: InputDecoration(
                labelText: 'Senha',
                hintText: 'Mínimo de 8 caracteres',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: controller.obscurePassword.value ? 'Mostrar senha' : 'Ocultar senha',
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
                onPressed: () => context.go('/forgot-password'),
                child: const Text('Esqueci minha senha'),
              ),
            ),
            const SizedBox(height: 12),
            PrimaryLoadingButton(
              label: 'Entrar',
              icon: Icons.arrow_forward_rounded,
              isLoading: controller.isLoading.value,
              onPressed: controller.submit,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text('Ainda não tem uma conta?'),
                TextButton(
                  onPressed: () => context.go('/register'),
                  child: const Text('Criar conta'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
