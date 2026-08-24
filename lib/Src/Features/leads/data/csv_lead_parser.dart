import 'dart:convert';
import 'dart:typed_data';

import 'package:agente_vendas_saas/Src/Core/api/api_exception.dart';
import 'package:agente_vendas_saas/Src/Features/leads/domain/lead_import_preview.dart';
import 'package:agente_vendas_saas/Src/Features/leads/domain/lead_input.dart';
import 'package:csv/csv.dart';

class CsvLeadParser {
  LeadImportPreview parse(Uint8List bytes) {
    final content = utf8.decode(bytes, allowMalformed: true).trim();
    if (content.isEmpty) {
      throw const ApiException(
        code: 'VALIDATION_ERROR',
        message: 'O arquivo CSV está vazio.',
      );
    }

    final table = csv.decode(content);
    if (table.length < 2) {
      throw const ApiException(
        code: 'VALIDATION_ERROR',
        message: 'Inclua um cabeçalho e pelo menos um lead no arquivo.',
      );
    }

    final headers = table.first.map(_normalizeHeader).toList(growable: false);
    if (!headers.contains('name')) {
      throw const ApiException(
        code: 'VALIDATION_ERROR',
        message: 'O CSV precisa conter a coluna "nome" ou "name".',
      );
    }

    final previewRows = <LeadImportPreviewRow>[];
    for (var rowIndex = 1; rowIndex < table.length; rowIndex++) {
      final row = table[rowIndex];
      if (row.every((dynamic value) => value.toString().trim().isEmpty)) continue;

      final values = <String, String>{};
      for (var column = 0; column < headers.length; column++) {
        if (column < row.length && headers[column].isNotEmpty) {
          values[headers[column]] = row[column].toString().trim();
        }
      }

      final email = _emptyToNull(values['email']);
      final phone = _emptyToNull(values['phone']);
      final name = values['name']?.trim() ?? '';
      final errors = <String>[
        if (name.isEmpty) 'Nome obrigatório',
        if (phone == null && email == null) 'Informe telefone ou e-mail',
        if (email != null && !_emailPattern.hasMatch(email)) 'E-mail inválido',
      ];

      previewRows.add(
        LeadImportPreviewRow(
          line: rowIndex + 1,
          errors: errors,
          input: LeadInput(
            name: name,
            phone: phone,
            email: email,
            company: _emptyToNull(values['company']),
            source: _normalizeSource(values['source']),
            status: _normalizeStatus(values['status']),
            tags: _parseTags(values['tags']),
            score: (int.tryParse(values['score'] ?? '') ?? 0).clamp(0, 100).toInt(),
          ),
        ),
      );
    }

    if (previewRows.isEmpty) {
      throw const ApiException(
        code: 'VALIDATION_ERROR',
        message: 'Nenhuma linha de lead foi encontrada no CSV.',
      );
    }
    return LeadImportPreview(rows: previewRows);
  }

  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String _normalizeHeader(dynamic raw) {
    final value = _plain(raw.toString().replaceFirst('\u{FEFF}', ''));
    return const <String, String>{
          'nome': 'name',
          'name': 'name',
          'telefone': 'phone',
          'celular': 'phone',
          'phone': 'phone',
          'email': 'email',
          'e-mail': 'email',
          'empresa': 'company',
          'company': 'company',
          'origem': 'source',
          'source': 'source',
          'status': 'status',
          'etapa': 'status',
          'tags': 'tags',
          'etiquetas': 'tags',
          'score': 'score',
          'pontuacao': 'score',
        }[value] ??
        '';
  }

  static String _normalizeSource(String? raw) {
    return switch (_plain(raw ?? '')) {
      'site' || 'website' => 'website',
      'whatsapp' => 'whatsapp',
      'instagram' => 'instagram',
      'indicacao' || 'referral' => 'referral',
      'campanha' || 'campaign' => 'campaign',
      'manual' => 'manual',
      _ => 'import',
    };
  }

  static String _normalizeStatus(String? raw) {
    return switch (_plain(raw ?? '')) {
      'contatado' || 'contacted' => 'contacted',
      'qualificado' || 'qualified' => 'qualified',
      'proposta' || 'proposal' => 'proposal',
      'ganho' || 'won' => 'won',
      'perdido' || 'lost' => 'lost',
      _ => 'new',
    };
  }

  static List<String> _parseTags(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const <String>[];
    return raw
        .split(RegExp(r'[,;|]'))
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  static String _plain(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[áàãâä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòõôö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll('ç', 'c');
  }

  static String? _emptyToNull(String? value) {
    final clean = value?.trim();
    return clean == null || clean.isEmpty ? null : clean;
  }
}
