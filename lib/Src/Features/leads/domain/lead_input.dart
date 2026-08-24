import 'package:agente_vendas_saas/Src/Shared/models/lead_model.dart';

class LeadInput {
  const LeadInput({
    required this.name,
    this.phone,
    this.email,
    this.company,
    this.source = 'manual',
    this.status = 'new',
    this.tags = const <String>[],
    this.ownerId,
    this.score = 0,
  });

  final String name;
  final String? phone;
  final String? email;
  final String? company;
  final String source;
  final String status;
  final List<String> tags;
  final String? ownerId;
  final int score;

  factory LeadInput.fromLead(LeadModel lead) {
    return LeadInput(
      name: lead.name,
      phone: lead.phone,
      email: lead.email,
      company: lead.company,
      source: lead.source,
      status: lead.status,
      tags: lead.tags,
      ownerId: lead.ownerId,
      score: lead.score,
    );
  }

  factory LeadInput.fromJson(Map<String, dynamic> json) {
    return LeadInput(
      name: json['name']?.toString().trim() ?? '',
      phone: _nullable(json['phone']),
      email: _nullable(json['email']),
      company: _nullable(json['company']),
      source: json['source']?.toString() ?? 'import',
      status: json['status']?.toString() ?? 'new',
      tags: (json['tags'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic item) => item.toString())
          .toList(growable: false),
      ownerId: _nullable(json['ownerId']),
      score: int.tryParse(json['score']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name.trim(),
      'phone': _clean(phone),
      'email': _clean(email),
      'company': _clean(company),
      'source': source,
      'status': status,
      'tags': tags,
      'ownerId': _clean(ownerId),
      'score': score,
    };
  }

  static String? _nullable(dynamic value) => _clean(value?.toString());

  static String? _clean(String? value) {
    final clean = value?.trim();
    return clean == null || clean.isEmpty ? null : clean;
  }
}
