import 'package:agente_vendas_saas/Src/Shared/models/agent_models.dart';

class AgentConfigurationInput {
  const AgentConfigurationInput({
    required this.name,
    required this.objective,
    required this.persona,
    required this.tone,
    required this.mode,
    required this.productOffer,
    required this.initialMessage,
    required this.isActive,
    required this.rules,
    required this.qualificationQuestions,
    required this.schedule,
    required this.policies,
    this.expectedVersion,
  });

  final String name;
  final String objective;
  final String persona;
  final String tone;
  final String mode;
  final String productOffer;
  final String initialMessage;
  final bool isActive;
  final List<String> rules;
  final List<String> qualificationQuestions;
  final AgentScheduleModel schedule;
  final AgentPoliciesModel policies;
  final int? expectedVersion;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name.trim(),
        'objective': objective.trim(),
        'persona': persona.trim(),
        'tone': tone,
        'mode': mode,
        'productOffer': productOffer.trim(),
        'initialMessage': initialMessage.trim(),
        'isActive': isActive,
        'rules': rules.map((String item) => item.trim()).toList(growable: false),
        'qualificationQuestions': qualificationQuestions
            .map((String item) => item.trim())
            .toList(growable: false),
        'schedule': schedule.toJson(),
        'policies': policies.toJson(),
        if (expectedVersion != null) 'expectedVersion': expectedVersion,
      };
}
