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

  Map<String, dynamic> toJson() {
    final cleanInitialMessage = initialMessage.trim();
    final instructions = _legacyInstructions();

    return <String, dynamic>{
      'name': name.trim(),
      'objective': objective.trim(),
      'persona': persona.trim(),
      'tone': tone,
      'mode': mode,
      'productOffer': productOffer.trim(),
      'initialMessage': cleanInitialMessage,
      'isActive': isActive,
      'rules': rules.map((String item) => item.trim()).toList(growable: false),
      'qualificationQuestions': qualificationQuestions
          .map((String item) => item.trim())
          .toList(growable: false),
      'schedule': schedule.toJson(),
      'policies': policies.toJson(),

      // Compatibilidade com o contrato antigo que ainda está ativo no backend.
      // O backend atual devolve active/greeting/instructions em vez de
      // isActive/initialMessage e dos campos comerciais estruturados.
      'active': isActive,
      'greeting': cleanInitialMessage,
      'instructions': instructions,
      'language': 'pt-BR',

      if (expectedVersion != null) 'expectedVersion': expectedVersion,
    };
  }

  String _legacyInstructions() {
    final buffer = StringBuffer()
      ..writeln('CORMEX_AGENT_CONFIG_V1')
      ..writeln('[OBJECTIVE]')
      ..writeln(objective.trim())
      ..writeln('[PERSONA]')
      ..writeln(persona.trim())
      ..writeln('[PRODUCT_OFFER]')
      ..writeln(productOffer.trim())
      ..writeln('[RULES]');

    for (final rule in rules) {
      final value = rule.trim();
      if (value.isNotEmpty) buffer.writeln('- $value');
    }

    buffer.writeln('[QUALIFICATION_QUESTIONS]');
    for (final question in qualificationQuestions) {
      final value = question.trim();
      if (value.isNotEmpty) buffer.writeln('- $value');
    }

    return buffer.toString().trim();
  }
}
