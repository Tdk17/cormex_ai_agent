import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AcquisitionStatusBadge extends StatelessWidget {
  const AcquisitionStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final data = _data(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: data.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: data.color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: data.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            data.label,
            style: TextStyle(
              color: data.color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  static ({String label, Color color}) _data(String value) => switch (value) {
        'draft' => (label: 'Rascunho', color: AppColors.textSecondary),
        'preparing' => (label: 'Preparando', color: AppColors.blue),
        'review' => (label: 'Em revisão', color: AppColors.warning),
        'active' => (label: 'Ativa', color: AppColors.accent),
        'paused' => (label: 'Pausada', color: AppColors.warning),
        'finished' => (label: 'Encerrada', color: AppColors.ink),
        'authorization_error' =>
          (label: 'Reconectar conta', color: AppColors.danger),
        'publication_error' =>
          (label: 'Falha na publicação', color: AppColors.danger),
        'payment_issue' =>
          (label: 'Problema de pagamento', color: AppColors.danger),
        _ => (label: value, color: AppColors.textSecondary),
      };
}
