import 'package:agente_vendas_saas/Src/Features/pipeline/domain/opportunity_input.dart';
import 'package:agente_vendas_saas/Src/Shared/models/pipeline_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OpportunityModel', () {
    test('normaliza DTO do Cloud Code e datas Parse', () {
      final opportunity = OpportunityModel.fromJson(<String, dynamic>{
        'objectId': 'opp_1',
        'workspaceId': 'ws_1',
        'leadId': 'lead_1',
        'stageId': 'negotiation',
        'title': 'Plano Enterprise',
        'companyName': 'Empresa Exemplo',
        'contactName': 'Marina Souza',
        'value': 45000,
        'probability': 70,
        'source': 'website',
        'outcome': 'open',
        'createdAt': <String, dynamic>{
          '__type': 'Date',
          'iso': '2026-08-20T12:00:00.000Z',
        },
        'updatedAt': '2026-08-24T16:30:00.000Z',
      });

      expect(opportunity.id, 'opp_1');
      expect(opportunity.value, 45000.0);
      expect(opportunity.createdAt.toUtc().toIso8601String(),
          '2026-08-20T12:00:00.000Z');
      expect(opportunity.updatedAt.toUtc().toIso8601String(),
          '2026-08-24T16:30:00.000Z');
    });

    test('copyWith preserva dados e altera somente movimento', () {
      final opportunity = OpportunityModel.fromJson(<String, dynamic>{
        'id': 'opp_1',
        'workspaceId': 'ws_1',
        'leadId': 'lead_1',
        'stageId': 'proposal',
        'title': 'Proposta anual',
        'companyName': 'Empresa Exemplo',
        'contactName': 'Marina Souza',
        'value': 1000,
        'probability': 50,
        'source': 'manual',
        'outcome': 'open',
        'createdAt': '2026-08-20T12:00:00.000Z',
        'updatedAt': '2026-08-20T12:00:00.000Z',
      });

      final moved = opportunity.copyWith(stageId: 'closed', outcome: 'won');

      expect(moved.stageId, 'closed');
      expect(moved.outcome, 'won');
      expect(moved.title, opportunity.title);
      expect(moved.value, opportunity.value);
    });
  });

  test('OpportunityInput limpa produto vazio e serializa data em UTC', () {
    final payload = OpportunityInput(
      leadId: 'lead_1',
      stageId: 'new_lead',
      title: ' Nova oportunidade ',
      companyName: ' Empresa ',
      contactName: ' Marina ',
      value: 1000,
      probability: 20,
      product: '   ',
      source: 'manual',
      nextActivityAt: DateTime.parse('2026-08-26T10:00:00-03:00'),
    ).toJson();

    expect(payload['title'], 'Nova oportunidade');
    expect(payload['companyName'], 'Empresa');
    expect(payload['product'], isNull);
    expect(payload['nextActivityAt'], '2026-08-26T13:00:00.000Z');
  });
}
