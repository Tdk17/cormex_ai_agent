import 'package:agente_vendas_saas/Src/Core/di/service_locator.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/cadastro_controller.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/widgets/auth_layout.dart';
import 'package:agente_vendas_saas/Src/Shared/components/form_error_banner.dart';
import 'package:agente_vendas_saas/Src/Shared/components/primary_loading_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';

class RegisterPage extends SignalWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = sl<CadastroController>();
    final error = controller.errorMessage.value;

    return AuthLayout(
      title: 'Crie sua operação de vendas',
      subtitle: 'Sua conta começa gratuita e leva menos de dois minutos.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (error != null) ...<Widget>[
            FormErrorBanner(
              message: error,
              correlationId: sl<AuthController>().correlationId.value,
            ),
            const SizedBox(height: 18),
          ],
          TextField(
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            onChanged: (String value) => controller.name.value = value,
            decoration: const InputDecoration(
              labelText: 'Nome completo',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onChanged: (String value) => controller.email.value = value,
            decoration: const InputDecoration(
              labelText: 'E-mail profissional',
              hintText: 'voce@empresa.com',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            obscureText: controller.obscurePassword.value,
            textInputAction: TextInputAction.next,
            onChanged: (String value) => controller.password.value = value,
            decoration: InputDecoration(
              labelText: 'Senha',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: controller.togglePasswordVisibility,
                icon: Icon(
                  controller.obscurePassword.value
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            obscureText: controller.obscurePassword.value,
            textInputAction: TextInputAction.done,
            onChanged: (String value) => controller.confirmPassword.value = value,
            onSubmitted: (_) => controller.submit(),
            decoration: const InputDecoration(
              labelText: 'Confirmar senha',
              prefixIcon: Icon(Icons.verified_user_outlined),
            ),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: controller.acceptedTerms.value,
            onChanged: (bool? value) => controller.acceptedTerms.value = value ?? false,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              'Concordo com os Termos de Uso e a Política de Privacidade.',
              style: TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(height: 14),
          PrimaryLoadingButton(
            label: 'Criar minha conta',
            icon: Icons.arrow_forward_rounded,
            isLoading: controller.isLoading.value,
            onPressed: controller.submit,
          ),
          const SizedBox(height: 18),
          Center(
            child: TextButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Voltar para o login'),
            ),
          ),
        ],
      ),
    );
  }
}
