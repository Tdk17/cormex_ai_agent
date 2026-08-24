import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AppBrand extends StatelessWidget {
  const AppBrand({super.key, this.light = false, this.compact = false});

  final bool light;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final foreground = light ? Colors.white : AppColors.ink;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: light ? Colors.white.withValues(alpha: 0.16) : AppColors.primary,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(Icons.auto_awesome_rounded, color: light ? Colors.white : Colors.white),
        ),
        if (!compact) ...<Widget>[
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Agente de Vendas',
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                'IA comercial',
                style: TextStyle(
                  color: foreground.withValues(alpha: 0.66),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
