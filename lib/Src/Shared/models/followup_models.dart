class FollowUpRuleModel {
  const FollowUpRuleModel({
    required this.id,
    required this.name,
    required this.delayMinutes,
    required this.condition,
    required this.active,
    this.channel = 'whatsapp',
    this.message = '',
    this.maxAttempts = 1,
    this.stopOnReply = true,
    this.stopOnLost = true,
    this.version = 0,
  });

  final String id;
  final String name;
  final int delayMinutes;
  final String condition;
  final bool active;
  final String channel;
  final String message;
  final int maxAttempts;
  final bool stopOnReply;
  final bool stopOnLost;
  final int version;

  factory FollowUpRuleModel.fromJson(Map<String, dynamic> json) {
    return FollowUpRuleModel(
      id: (json['id'] ?? json['objectId'] ?? '').toString(),
      name: json['name']?.toString() ?? '',
      delayMinutes: (json['delayMinutes'] as num?)?.toInt() ?? 0,
      condition: json['condition']?.toString() ?? 'no_reply',
      active: json['active'] == true,
      channel: json['channel']?.toString() ?? 'whatsapp',
      message: json['message']?.toString() ?? '',
      maxAttempts: (json['maxAttempts'] as num?)?.toInt() ?? 1,
      stopOnReply: json['stopOnReply'] != false,
      stopOnLost: json['stopOnLost'] != false,
      version: (json['version'] as num?)?.toInt() ?? 0,
    );
  }
}

class TaskModel {
  const TaskModel({
    required this.id,
    required this.title,
    required this.status,
    required this.dueAt,
    this.workspaceId,
    this.leadId,
    this.customerId,
    this.accountId,
    this.opportunityId,
    this.ownerId,
  });

  final String id;
  final String title;
  final String status;
  final DateTime dueAt;
  final String? workspaceId;
  final String? leadId;
  final String? customerId;
  final String? accountId;
  final String? opportunityId;
  final String? ownerId;

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: (json['id'] ?? json['objectId'] ?? '').toString(),
      title: json['title']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      dueAt: _date(json['dueAt']) ?? DateTime.now(),
      workspaceId: json['workspaceId']?.toString(),
      leadId: json['leadId']?.toString(),
      customerId: json['customerId']?.toString(),
      accountId: json['accountId']?.toString(),
      opportunityId: json['opportunityId']?.toString(),
      ownerId: json['ownerId']?.toString(),
    );
  }

  static DateTime? _date(dynamic value) {
    if (value is Map && value['iso'] != null) {
      return DateTime.tryParse(value['iso'].toString());
    }
    return DateTime.tryParse(value?.toString() ?? '');
  }
}
