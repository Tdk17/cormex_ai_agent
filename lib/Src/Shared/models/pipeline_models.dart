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
}

class OpportunityModel {
  const OpportunityModel({
    required this.id,
    required this.leadId,
    required this.stageId,
    required this.title,
    required this.value,
    required this.updatedAt,
  });

  final String id;
  final String leadId;
  final String stageId;
  final String title;
  final double value;
  final DateTime updatedAt;

  factory OpportunityModel.fromJson(Map<String, dynamic> json) {
    return OpportunityModel(
      id: (json['id'] ?? json['objectId'] ?? '').toString(),
      leadId: json['leadId']?.toString() ?? '',
      stageId: json['stageId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
