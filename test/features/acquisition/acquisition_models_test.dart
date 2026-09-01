import 'package:agente_vendas_saas/Src/Features/acquisition/domain/acquisition_campaign_input.dart';
import 'package:agente_vendas_saas/Src/Shared/models/acquisition_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AcquisitionCampaignModel', () {
    test('normaliza campanha retornada pela API', () {
      final model = AcquisitionCampaignModel.fromJson(<String, dynamic>{
        'objectId': 'campaign-1',
        'name': 'Campanha SC',
        'productName': 'CormeX',
        'objective': 'leads',
        'channels': <String>['meta'],
        'status': 'active',
        'budgetType': 'daily',
        'budgetAmount': 50,
        'investment': 150,
        'leads': 10,
        'conversions': 2,
        'version': 3,
        'updatedAt': '2026-09-01T12:00:00.000Z',
      });

      expect(model.id, 'campaign-1');
      expect(model.channels, <String>['meta']);
      expect(model.canPause, isTrue);
      expect(model.canResume, isFalse);
      expect(model.version, 3);
    });
  });

  group('AcquisitionCampaignInput', () {
    test('gera payload aninhado e mantém expectedVersion', () {
      final input = AcquisitionCampaignInput(
        name: 'Campanha SC',
        productName: 'CormeX',
        productDescription: 'Agente de vendas',
        offer: 'Demonstração',
        productUrl: 'https://example.com',
        mediaUrls: const <String>['https://example.com/image.jpg'],
        objective: 'leads',
        channels: const <String>['meta'],
        locations: const <String>['Santa Catarina'],
        ageMin: 25,
        ageMax: 55,
        interests: const <String>['software'],
        broadAudience: true,
        budgetType: 'daily',
        budgetAmount: 50,
        startAt: DateTime.utc(2026, 9, 1),
        endAt: null,
        headline: 'Venda mais',
        primaryText: 'Centralize sua operação comercial.',
        description: 'Conheça o CormeX.',
        callToAction: 'LEARN_MORE',
        destinationType: 'whatsapp',
        destinationUrl: '',
        captureFields: const <String>['name', 'phone'],
        consentText: '',
        initialMessage: 'Olá! Como posso ajudar?',
        qualificationQuestions: const <String>['Qual é sua equipe?'],
        pipelineStageId: 'new_lead',
        tags: const <String>['campaign'],
        onlyRegisterLead: false,
        expectedVersion: 4,
      );

      final json = input.toJson();
      expect(json['expectedVersion'], 4);
      expect((json['budget'] as Map<String, dynamic>)['amount'], 50);
      expect((json['audience'] as Map<String, dynamic>)['locations'], <String>['Santa Catarina']);
      expect((json['automation'] as Map<String, dynamic>)['pipelineStageId'], 'new_lead');
    });
  });
}
