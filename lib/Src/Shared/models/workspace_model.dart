class WorkspaceModel {
  const WorkspaceModel({
    required this.id,
    required this.name,
    required this.timezone,
    this.companySegment,
  });

  final String id;
  final String name;
  final String timezone;
  final String? companySegment;

  factory WorkspaceModel.fromJson(Map<String, dynamic> json) {
    return WorkspaceModel(
      id: (json['id'] ?? json['objectId'] ?? '').toString(),
      name: json['name']?.toString() ?? 'Workspace',
      timezone: json['timezone']?.toString() ?? 'America/Sao_Paulo',
      companySegment: json['companySegment']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'timezone': timezone,
        'companySegment': companySegment,
      };
}
