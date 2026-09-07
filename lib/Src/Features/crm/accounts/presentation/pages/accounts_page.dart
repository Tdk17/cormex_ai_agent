import 'package:agente_vendas_saas/Src/Features/crm/shared/presentation/widgets/crm_module_page.dart';
import 'package:flutter/material.dart';

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CrmModulePage(
      title: 'Empresas / Contas',
      description: 'Organizações vinculadas a contatos, clientes e oportunidades B2B.',
      icon: Icons.apartment_outlined,
      emptyTitle: 'Nenhuma empresa registrada',
      emptyDescription:
          'As contas empresariais aparecerão aqui quando o backend CRM disponibilizar os registros do workspace.',
      primaryLabel: 'Abrir clientes',
      primaryRoute: '/crm/customers',
    );
  }
}
