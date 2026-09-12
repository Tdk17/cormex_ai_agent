import 'package:agente_vendas_saas/Src/Core/api/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiException', () {
    test('preserva correlationId e traduz código conhecido', () {
      final exception = ApiException.fromMap(<String, dynamic>{
        'code': 'PLAN_LIMIT_REACHED',
        'message': 'Limite atingido',
        'correlationId': 'req_123',
        'details': <String, dynamic>{'limit': 100},
      });

      expect(exception.correlationId, 'req_123');
      expect(exception.details['limit'], 100);
      expect(exception.userMessage, contains('limite do seu plano'));
    });

    test('não expõe mensagem interna para código desconhecido', () {
      const exception = ApiException(
        code: 'INTERNAL_ERROR',
        message: 'stack trace sensível',
      );

      expect(exception.userMessage, isNot(contains('stack trace')));
    });

    test('normaliza código e preserva mensagem segura do backend', () {
      final exception = ApiException.fromMap(<String, dynamic>{
        'code': 'channel_not_connected',
        'message': 'Canal indisponível.',
      });

      expect(exception.code, 'CHANNEL_NOT_CONNECTED');
      expect(exception.userMessage, contains('Conecte o canal'));
    });

    test('exibe mensagem de regra de negócio para código não mapeado', () {
      const exception = ApiException(
        code: 'CAMPAIGN_REVIEW_REQUIRED',
        message: 'Revise os campos destacados antes de publicar.',
      );

      expect(exception.userMessage, contains('Revise os campos'));
    });
  });
}
