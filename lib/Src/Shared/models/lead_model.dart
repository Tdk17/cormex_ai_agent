class LeadModel {
  const LeadModel({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.status,
    required this.source,
    required this.score,
    required this.createdAt,
    required this.updatedAt,
    this.phone,
    this.email,
    this.company,
    this.tags = const <String>[],
    this.ownerId,
    this.lastContactAt,
  });

  final String id;
  final String workspaceId;
  final String name;
  final String? phone;
  final String? email;
  final String? company;
  final String source;
  final String status;
  final List<String> tags;
  final String? ownerId;
  final int score;
  final DateTime? lastContactAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    return LeadModel(
      id: (json['id'] ?? json['objectId'] ?? '').toString(),
      workspaceId: json['workspaceId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      company: json['company']?.toString(),
      source: json['source']?.toString() ?? 'manual',
      status: json['status']?.toString() ?? 'new',
      tags: (json['tags'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic item) => item.toString())
          .toList(growable: false),
      ownerId: json['ownerId']?.toString(),
      score: (json['score'] as num?)?.toInt() ?? 0,
      lastContactAt: DateTime.tryParse(json['lastContactAt']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
