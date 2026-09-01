import 'package:agente_vendas_saas/Src/Features/agent/domain/agent_configuration_input.dart';
import 'package:agente_vendas_saas/Src/Shared/models/agent_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('converte configuração completa do agente', () {
    final agent = SalesAgentModel.fromJson(<String, dynamic>{
      'objectId': 'agent_1',
      'workspaceId': 'workspace_1',
      'name': 'Clara',
      'objective': 'Qualificar leads e apresentar o plano adequado.',
      'persona': 'Consultora comercial experiente e objetiva.',
      'tone': 'consultive',
      'mode': 'assist',
      'productOffer': 'CormeX Enterprise',
      'initialMessage': 'Olá! Como posso ajudar sua empresa?',
      'isActive': true,
      'rules': <String>['Não inventar descontos'],
      'qualificationQuestions': <String>['Qual é o tamanho da equipe?'],
      'schedule': <String, dynamic>{
        'enabled': true,
        'timezone': 'America/Sao_Paulo',
        'daysOfWeek': <int>[5, 1, 3],
        'startTime': '08:00',
        'endTime': '18:00',
      },
      'policies': <String, dynamic>{
        'maxResponseCharacters': 900,
        'maxAttemptsBeforeHandoff': 4,
        'askForName': true,
        'askForPhone': true,
        'allowPricePresentation': false,
        'allowFollowUp': true,
        'followUpDelayMinutes': 720,
        'handoffOnRequest': true,
      },
      'version': 7,
      'updatedAt': <String, dynamic>{
        '__type': 'Date',
        'iso': '2026-08-25T14:00:00.000Z',
      },
    });

    expect(agent.id, 'agent_1');
    expect(agent.schedule.daysOfWeek, <int>[1, 3, 5]);
    expect(agent.policies.maxResponseCharacters, 900);
    expect(agent.policies.allowPricePresentation, isFalse);
    expect(agent.version, 7);
    expect(agent.updatedAt?.isUtc, isTrue);
  });

  test('serializa input com versão esperada para evitar sobrescrita', () {
    const input = AgentConfigurationInput(
      name: 'Clara',
      objective: 'Qualificar leads interessados.',
      persona: 'Consultora comercial experiente.',
      tone: 'consultive',
      mode: 'auto',
      productOffer: 'Plano Enterprise',
      initialMessage: 'Olá! Posso ajudar?',
      isActive: true,
      rules: <String>['Não prometer descontos'],
      qualificationQuestions: <String>['Qual é o orçamento?'],
      schedule: AgentScheduleModel(
        enabled: true,
        timezone: 'America/Sao_Paulo',
        daysOfWeek: <int>[1, 2, 3, 4, 5],
        startTime: '08:00',
        endTime: '18:00',
      ),
      policies: AgentPoliciesModel(
        maxResponseCharacters: 700,
        maxAttemptsBeforeHandoff: 3,
        askForName: true,
        askForPhone: true,
        allowPricePresentation: true,
        allowFollowUp: true,
        followUpDelayMinutes: 1440,
        handoffOnRequest: true,
      ),
      expectedVersion: 4,
    );

    final json = input.toJson();

    expect(json['expectedVersion'], 4);
    expect(json['mode'], 'auto');
    expect((json['schedule'] as Map)['timezone'], 'America/Sao_Paulo');
  });

  test('converte diagnóstico estruturado do sandbox', () {
    final reply = AgentTestReplyModel.fromJson(<String, dynamic>{
      'content': 'Posso preparar uma proposta para 12 usuários.',
      'productConsulted': 'CormeX Enterprise',
      'rulesUsed': <String>['Não inventar descontos'],
      'suggestedAction': 'Solicitar telefone',
      'warnings': <String>['Preço precisa de confirmação'],
      'shouldHandoff': true,
    });

    expect(reply.content, contains('proposta'));
    expect(reply.rulesUsed, hasLength(1));
    expect(reply.warnings, hasLength(1));
    expect(reply.shouldHandoff, isTrue);
  });
}
