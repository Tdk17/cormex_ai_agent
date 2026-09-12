import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:flutter/material.dart';

class FormErrorBanner extends StatelessWidget {
  const FormErrorBanner({super.key, required this.message, this.correlationId});

  final String message;

  // Mantido apenas por compatibilidade com os controllers. Identificadores de
  // correlação são úteis para observabilidade interna, mas nunca devem ser
  // exibidos na interface do cliente.
  final String? correlationId;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}
