import 'package:agente_vendas_saas/Src/Features/leads/domain/lead_input.dart';

class LeadImportPreviewRow {
  const LeadImportPreviewRow({
    required this.line,
    required this.input,
    this.errors = const <String>[],
  });

  final int line;
  final LeadInput input;
  final List<String> errors;

  bool get isValid => errors.isEmpty;
}

class LeadImportPreview {
  const LeadImportPreview({required this.rows});

  final List<LeadImportPreviewRow> rows;

  int get validCount => rows.where((LeadImportPreviewRow row) => row.isValid).length;
  int get invalidCount => rows.length - validCount;

  List<Map<String, dynamic>> get validPayload => rows
      .where((LeadImportPreviewRow row) => row.isValid)
      .map((LeadImportPreviewRow row) => row.input.toJson())
      .toList(growable: false);
}
