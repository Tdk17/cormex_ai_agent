import 'package:agente_vendas_saas/Src/Features/crm/shared/presentation/widgets/crm_module_page.dart';
import 'package:flutter/material.dart';

class CustomersPage extends StatelessWidget {
  const CustomersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CrmModulePage(
      title: 'Clientes',
      description: 'Pessoas convertidas e ativas, com histórico comercial consolidado.',
      icon: Icons.person_outline_rounded,
      emptyTitle: 'Nenhum cliente registrado',
      emptyDescription:
          'Os clientes serão criados a partir da conversão dos leads. Nenhum dado fictício é exibido nesta tela.',
      primaryLabel: 'Abrir leads',
      primaryRoute: '/crm/leads',
    );
  }
}
