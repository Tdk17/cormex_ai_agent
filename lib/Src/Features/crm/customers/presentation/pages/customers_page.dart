import 'package:agente_vendas_saas/Src/Features/crm/shared/presentation/widgets/crm_directory_page.dart';
import 'package:flutter/material.dart';

class CustomersPage extends StatelessWidget {
  const CustomersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CrmDirectoryPage(type: CrmDirectoryType.customers);
  }
}
