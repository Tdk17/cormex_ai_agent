import 'package:agente_vendas_saas/Src/App/theme/app_colors.dart';
import 'package:agente_vendas_saas/Src/Core/di/service_locator.dart';
import 'package:agente_vendas_saas/Src/Features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:agente_vendas_saas/Src/Shared/components/app_brand.dart';
import 'package:agente_vendas_saas/Src/Shared/components/form_error_banner.dart';
import 'package:agente_vendas_saas/Src/Shared/components/primary_loading_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';

class OnboardingPage extends SignalStatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late final OnboardingController controller;

  @override
  void initState() {
    super.initState();
    controller = sl<OnboardingController>()..reset();
  }

  @override
  Widget build(BuildContext context) {
    final step = controller.currentStep.value;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Row(
                children: <Widget>[
                  const AppBrand(),
                  const Spacer(),
                  Text(
                    'Etapa ${step + 1} de 3',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            LinearProgressIndicator(
              value: (step + 1) / 3,
              minHeight: 3,
              color: AppColors.accent,
              backgroundColor: AppColors.border,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 42, 22, 36),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 650),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      child: Column(
                        key: ValueKey<int>(step),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _StepHeader(step: step),
                          const SizedBox(height: 30),
                          if (controller.errorMessage.value != null) ...<Widget>[
                            FormErrorBanner(message: controller.errorMessage.value!),
                            const SizedBox(height: 20),
                          ],
                          _StepContent(step: step, controller: controller),
                          const SizedBox(height: 34),
                          Row(
                            children: <Widget>[
                              if (step > 0) ...<Widget>[
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: controller.isLoading.value
                                        ? null
                                        : controller.previousStep,
                                    icon: const Icon(Icons.arrow_back_rounded),
                                    label: const Text('Voltar'),
                                  ),
                                ),
                                const SizedBox(width: 14),
                              ],
                              Expanded(
                                flex: step > 0 ? 2 : 1,
                                child: PrimaryLoadingButton(
                                  label: step == 2 ? 'Criar workspace' : 'Continuar',
                                  icon: Icons.arrow_forward_rounded,
                                  isLoading: controller.isLoading.value,
                                  onPressed: () async {
                                    if (step < 2) {
                                      controller.nextStep();
                                      return;
                                    }
                                    final success = await controller.finish();
                                    if (success && context.mounted) context.go('/dashboard');
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    const titles = <String>[
      'Vamos criar seu workspace',
      'Conte um pouco sobre a empresa',
      'Defina o primeiro objetivo do agente',
    ];
    const subtitles = <String>[
      'O workspace mantém usuários, leads, conversas e métricas isolados.',
      'Essas informações ajudam a personalizar sua operação comercial.',
      'O agente nasce em modo assistido: sua equipe revisa antes de enviar.',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            <IconData>[
              Icons.domain_add_outlined,
              Icons.storefront_outlined,
              Icons.auto_awesome_outlined,
            ][step],
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 20),
        Text(titles[step], style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 10),
        Text(
          subtitles[step],
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _StepContent extends SignalWidget {
  const _StepContent({required this.step, required this.controller});

  final int step;
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    if (step == 0) {
      return Column(
        children: <Widget>[
          TextFormField(
            initialValue: controller.workspaceName.value,
            textCapitalization: TextCapitalization.words,
            onChanged: (String value) => controller.workspaceName.value = value,
            decoration: const InputDecoration(
              labelText: 'Nome da empresa',
              hintText: 'Ex.: Gênesis System',
              prefixIcon: Icon(Icons.business_outlined),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: controller.timezone.value,
            decoration: const InputDecoration(
              labelText: 'Fuso horário',
              prefixIcon: Icon(Icons.schedule_outlined),
            ),
            items: const <DropdownMenuItem<String>>[
              DropdownMenuItem(
                value: 'America/Sao_Paulo',
                child: Text('Brasília • GMT-3'),
              ),
              DropdownMenuItem(
                value: 'America/Manaus',
                child: Text('Manaus • GMT-4'),
              ),
              DropdownMenuItem(
                value: 'America/Rio_Branco',
                child: Text('Rio Branco • GMT-5'),
              ),
            ],
            onChanged: (String? value) {
              if (value != null) controller.timezone.value = value;
            },
          ),
        ],
      );
    }

    if (step == 1) {
      const segments = <String>[
        'Software e tecnologia',
        'Comércio e distribuição',
        'Serviços profissionais',
        'Imobiliário',
        'Saúde e bem-estar',
        'Outro',
      ];
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: segments.map((String segment) {
          final selected = controller.companySegment.value == segment;
          return ChoiceChip(
            label: Text(segment),
            selected: selected,
            onSelected: (_) => controller.companySegment.value = segment,
          );
        }).toList(growable: false),
      );
    }

    return Column(
      children: <Widget>[
        TextFormField(
          initialValue: controller.agentName.value,
          textCapitalization: TextCapitalization.words,
          onChanged: (String value) => controller.agentName.value = value,
          decoration: const InputDecoration(
            labelText: 'Nome do agente',
            hintText: 'Ex.: Clara',
            prefixIcon: Icon(Icons.smart_toy_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: controller.agentObjective.value,
          minLines: 4,
          maxLines: 6,
          onChanged: (String value) => controller.agentObjective.value = value,
          decoration: const InputDecoration(
            alignLabelWithHint: true,
            labelText: 'Objetivo comercial',
            hintText: 'Ex.: Qualificar leads interessados no plano empresarial e agendar uma demonstração.',
          ),
        ),
      ],
    );
  }
}
