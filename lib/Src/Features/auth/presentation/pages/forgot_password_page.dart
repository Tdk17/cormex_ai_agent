import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:agente_vendas_saas/Src/Core/di/service_locator.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/forgot_password_controller.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/widgets/auth_layout.dart';
import 'package:agente_vendas_saas/Src/Shared/components/form_error_banner.dart';
import 'package:agente_vendas_saas/Src/Shared/components/primary_loading_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';

class ForgotPasswordPage extends SignalWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = sl<ForgotPasswordController>();
    return AuthLayout(
      title: 'Recupere seu acesso',
      subtitle: 'Enviaremos as instruções para o e-mail cadastrado.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (controller.emailSent.value) ...<Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: <Widget>[
                  Icon(Icons.mark_email_read_outlined, color: AppColors.primary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'E-mail enviado. Confira também sua caixa de spam.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],
          if (controller.errorMessage.value != null) ...<Widget>[
            FormErrorBanner(message: controller.errorMessage.value!),
            const SizedBox(height: 18),
          ],
          TextField(
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onChanged: (String value) => controller.email.value = value,
            onSubmitted: (_) => controller.submit(),
            decoration: const InputDecoration(
              labelText: 'E-mail',
              hintText: 'voce@empresa.com',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
          ),
          const SizedBox(height: 18),
          PrimaryLoadingButton(
            label: 'Enviar instruções',
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
