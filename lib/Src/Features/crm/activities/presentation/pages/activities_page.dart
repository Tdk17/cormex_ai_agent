import 'package:agente_vendas_saas/Src/Features/crm/shared/presentation/widgets/crm_module_page.dart';
import 'package:flutter/material.dart';

class ActivitiesPage extends StatelessWidget {
  const ActivitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CrmModulePage(
      title: 'Atividades',
      description: 'Tarefas, ligações, reuniões, mensagens e follow-ups do CRM.',
      icon: Icons.task_alt_outlined,
      emptyTitle: 'Nenhuma atividade registrada',
      emptyDescription:
          'As atividades do CRM serão consolidadas aqui sem criar mocks. Enquanto os novos endpoints não estiverem disponíveis, os follow-ups existentes continuam operando no módulo de automação.',
      primaryLabel: 'Abrir follow-ups',
      primaryRoute: '/automation/followups',
    );
  }
}
