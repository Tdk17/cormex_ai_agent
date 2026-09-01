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
  });
}
