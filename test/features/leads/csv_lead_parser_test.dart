import 'dart:convert';
import 'dart:typed_data';

import 'package:agente_vendas_saas/Src/Features/leads/data/csv_lead_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = CsvLeadParser();

  test('normaliza cabeçalhos e valores em português', () {
    const content = 'nome,email,empresa,origem,status,tags,score\n'
        'Marina Souza,marina@teste.com,Nexo,WhatsApp,Qualificado,"inbound; prioridade",91\n'
        'Sem Contato,,Empresa B,Site,Novo,,10';

    final preview = parser.parse(Uint8List.fromList(utf8.encode(content)));

    expect(preview.rows, hasLength(2));
    expect(preview.validCount, 1);
    expect(preview.invalidCount, 1);
    expect(preview.rows.first.input.source, 'whatsapp');
    expect(preview.rows.first.input.status, 'qualified');
    expect(preview.rows.first.input.tags, <String>['inbound', 'prioridade']);
    expect(preview.rows.first.input.score, 91);
    expect(preview.rows.last.errors, contains('Informe telefone ou e-mail'));
  });

  test('rejeita arquivo sem coluna de nome', () {
    const content = 'email,telefone\nlead@teste.com,+5511999999999';

    expect(
      () => parser.parse(Uint8List.fromList(utf8.encode(content))),
      throwsA(isA<Exception>()),
    );
  });
}
