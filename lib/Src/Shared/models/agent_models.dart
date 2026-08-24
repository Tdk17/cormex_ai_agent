class SalesAgentModel {
  const SalesAgentModel({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.objective,
    required this.persona,
    required this.tone,
    required this.mode,
    required this.rules,
    required this.qualificationQuestions,
  });

  final String id;
  final String workspaceId;
  final String name;
  final String objective;
  final String persona;
  final String tone;
  final String mode;
  final List<String> rules;
  final List<String> qualificationQuestions;

  factory SalesAgentModel.fromJson(Map<String, dynamic> json) {
    return SalesAgentModel(
      id: (json['id'] ?? json['objectId'] ?? '').toString(),
      workspaceId: json['workspaceId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      objective: json['objective']?.toString() ?? '',
      persona: json['persona']?.toString() ?? '',
      tone: json['tone']?.toString() ?? 'consultivo',
      mode: json['mode']?.toString() ?? 'assist',
      rules: _stringList(json['rules']),
      qualificationQuestions: _stringList(json['qualificationQuestions']),
    );
  }

  static List<String> _stringList(dynamic value) {
    return (value as List<dynamic>? ?? const <dynamic>[])
        .map((dynamic item) => item.toString())
        .toList(growable: false);
  }
}

class KnowledgeSourceModel {
  const KnowledgeSourceModel({
    required this.id,
    required this.agentId,
    required this.type,
    required this.title,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String agentId;
  final String type;
  final String title;
  final String status;
  final DateTime createdAt;

  factory KnowledgeSourceModel.fromJson(Map<String, dynamic> json) {
    return KnowledgeSourceModel(
      id: (json['id'] ?? json['objectId'] ?? '').toString(),
      agentId: json['agentId']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      title: json['title']?.toString() ?? 'Fonte sem título',
      status: json['status']?.toString() ?? 'processing',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
