class PipelineStageModel {
  const PipelineStageModel({
    required this.id,
    required this.name,
    required this.position,
    required this.color,
  });

  final String id;
  final String name;
  final int position;
  final String color;

  factory PipelineStageModel.fromJson(Map<String, dynamic> json) {
    return PipelineStageModel(
      id: (json['id'] ?? json['objectId'] ?? '').toString(),
      name: json['name']?.toString() ?? '',
      position: (json['position'] as num?)?.toInt() ?? 0,
      color: json['color']?.toString() ?? '#0B6B61',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'position': position,
      'color': color,
    };
  }
}

class PipelineOwnerModel {
  const PipelineOwnerModel({required this.id, required this.name});

  final String id;
  final String name;

  factory PipelineOwnerModel.fromJson(Map<String, dynamic> json) {
    return PipelineOwnerModel(
      id: (json['id'] ?? json['objectId'] ?? json['userId'] ?? '').toString(),
      name: (json['name'] ?? json['displayName'] ?? json['email'] ?? '').toString(),
    );
  }
}

class OpportunityModel {
  const OpportunityModel({
    required this.id,
    required this.workspaceId,
    required this.leadId,
    required this.stageId,
    required this.title,
    required this.companyName,
    required this.contactName,
    required this.value,
    required this.probability,
    required this.source,
    required this.outcome,
    required this.createdAt,
    required this.updatedAt,
    this.ownerId,
    this.ownerName,
    this.product,
    this.lastInteractionAt,
    this.nextActivityAt,
  });

  final String id;
  final String workspaceId;
  final String leadId;
  final String stageId;
  final String title;
  final String companyName;
  final String contactName;
  final double value;
  final int probability;
  final String? ownerId;
  final String? ownerName;
  final String? product;
  final String source;
  final String outcome;
  final DateTime? lastInteractionAt;
  final DateTime? nextActivityAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get daysWithoutInteraction {
    final reference = lastInteractionAt ?? createdAt;
    final days = DateTime.now().difference(reference).inDays;
    return days < 0 ? 0 : days;
  }

  factory OpportunityModel.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final company = json['companyName']?.toString() ??
        json['company']?.toString() ??
        json['title']?.toString() ??
        '';
    return OpportunityModel(
      id: (json['id'] ?? json['objectId'] ?? '').toString(),
      workspaceId: json['workspaceId']?.toString() ?? '',
      leadId: json['leadId']?.toString() ?? '',
      stageId: json['stageId']?.toString() ?? '',
      title: json['title']?.toString() ?? company,
      companyName: company,
      contactName: json['contactName']?.toString() ??
          json['leadName']?.toString() ??
          '',
      value: (json['value'] as num?)?.toDouble() ?? 0,
      probability: (json['probability'] as num?)?.toInt() ?? 0,
      ownerId: json['ownerId']?.toString(),
      ownerName: json['ownerName']?.toString(),
      product: json['product']?.toString(),
      source: json['source']?.toString() ?? 'manual',
      outcome: json['outcome']?.toString() ?? 'open',
      lastInteractionAt: _date(json['lastInteractionAt']),
      nextActivityAt: _date(json['nextActivityAt']),
      createdAt: _date(json['createdAt']) ?? now,
      updatedAt: _date(json['updatedAt']) ?? now,
    );
  }

  OpportunityModel copyWith({
    String? stageId,
    String? outcome,
    DateTime? updatedAt,
  }) {
    return OpportunityModel(
      id: id,
      workspaceId: workspaceId,
      leadId: leadId,
      stageId: stageId ?? this.stageId,
      title: title,
      companyName: companyName,
      contactName: contactName,
      value: value,
      probability: probability,
      ownerId: ownerId,
      ownerName: ownerName,
      product: product,
      source: source,
      outcome: outcome ?? this.outcome,
      lastInteractionAt: lastInteractionAt,
      nextActivityAt: nextActivityAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'workspaceId': workspaceId,
      'leadId': leadId,
      'stageId': stageId,
      'title': title,
      'companyName': companyName,
      'contactName': contactName,
      'value': value,
      'probability': probability,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'product': product,
      'source': source,
      'outcome': outcome,
      'lastInteractionAt': lastInteractionAt?.toUtc().toIso8601String(),
      'nextActivityAt': nextActivityAt?.toUtc().toIso8601String(),
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  static DateTime? _date(dynamic value) {
    if (value is Map && value['iso'] != null) {
      return DateTime.tryParse(value['iso'].toString());
    }
    return DateTime.tryParse(value?.toString() ?? '');
  }
}
