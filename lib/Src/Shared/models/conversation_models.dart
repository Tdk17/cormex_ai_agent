class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.workspaceId,
    required this.leadId,
    required this.leadName,
    required this.channel,
    required this.status,
    required this.agentMode,
    required this.lastMessagePreview,
    required this.unreadCount,
    required this.updatedAt,
    this.assignedUserId,
    this.assignedUserName,
    this.lastMessageAt,
  });

  final String id;
  final String workspaceId;
  final String leadId;
  final String leadName;
  final String channel;
  final String status;
  final String agentMode;
  final String? assignedUserId;
  final String? assignedUserName;
  final String lastMessagePreview;
  final DateTime? lastMessageAt;
  final DateTime updatedAt;
  final int unreadCount;

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final lead = json['lead'] is Map
        ? Map<String, dynamic>.from(json['lead'] as Map)
        : const <String, dynamic>{};
    final lastMessage = json['lastMessage'] is Map
        ? Map<String, dynamic>.from(json['lastMessage'] as Map)
        : const <String, dynamic>{};
    final assignedUser = json['assignedUser'] is Map
        ? Map<String, dynamic>.from(json['assignedUser'] as Map)
        : const <String, dynamic>{};
    final now = DateTime.now();
    return ConversationModel(
      id: (json['id'] ?? json['objectId'] ?? '').toString(),
      workspaceId: json['workspaceId']?.toString() ?? '',
      leadId: (lead['id'] ?? lead['objectId'] ?? json['leadId'] ?? '')
          .toString(),
      leadName: (lead['name'] ?? json['leadName'] ?? '').toString(),
      channel: json['channel']?.toString() ?? 'whatsapp',
      status: json['status']?.toString() ?? 'open',
      agentMode: (json['agentMode'] ?? json['mode'] ?? 'assist').toString(),
      assignedUserId:
          (assignedUser['id'] ??
                  assignedUser['objectId'] ??
                  json['assignedUserId'])
              ?.toString(),
      assignedUserName: (assignedUser['name'] ?? json['assignedUserName'])
          ?.toString(),
      lastMessagePreview:
          (lastMessage['preview'] ??
                  lastMessage['content'] ??
                  json['lastMessagePreview'] ??
                  '')
              .toString(),
      lastMessageAt: _date(lastMessage['sentAt'] ?? json['lastMessageAt']),
      updatedAt: _date(json['updatedAt']) ?? now,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }

  ConversationModel copyWith({
    String? status,
    String? agentMode,
    String? assignedUserId,
    String? assignedUserName,
    bool clearAssignment = false,
    String? lastMessagePreview,
    DateTime? lastMessageAt,
    DateTime? updatedAt,
    int? unreadCount,
  }) {
    return ConversationModel(
      id: id,
      workspaceId: workspaceId,
      leadId: leadId,
      leadName: leadName,
      channel: channel,
      status: status ?? this.status,
      agentMode: agentMode ?? this.agentMode,
      assignedUserId: clearAssignment
          ? null
          : assignedUserId ?? this.assignedUserId,
      assignedUserName: clearAssignment
          ? null
          : assignedUserName ?? this.assignedUserName,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  static DateTime? _date(dynamic value) {
    if (value is Map && value['iso'] != null) {
      return DateTime.tryParse(value['iso'].toString());
    }
    return DateTime.tryParse(value?.toString() ?? '');
  }
}

class MessageModel {
  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.direction,
    required this.senderType,
    required this.type,
    required this.content,
    required this.status,
    required this.sentAt,
    this.senderName,
  });

  final String id;
  final String conversationId;
  final String direction;
  final String senderType;
  final String? senderName;
  final String type;
  final String content;
  final String status;
  final DateTime sentAt;

  bool get isOutbound => direction == 'outbound';
  bool get isSystem => senderType == 'system';
  bool get isAi => senderType == 'ai';
  bool get isHuman => senderType == 'human';

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: (json['id'] ?? json['objectId'] ?? '').toString(),
      conversationId: json['conversationId']?.toString() ?? '',
      direction: json['direction']?.toString() ?? 'inbound',
      senderType: json['senderType']?.toString() ?? 'system',
      senderName: json['senderName']?.toString(),
      type: json['type']?.toString() ?? 'text',
      content: json['content']?.toString() ?? '',
      status: json['status']?.toString() ?? 'sent',
      sentAt: _date(json['sentAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _date(dynamic value) {
    if (value is Map && value['iso'] != null) {
      return DateTime.tryParse(value['iso'].toString());
    }
    return DateTime.tryParse(value?.toString() ?? '');
  }
}

class ConversationOwnerModel {
  const ConversationOwnerModel({required this.id, required this.name});

  final String id;
  final String name;

  factory ConversationOwnerModel.fromJson(Map<String, dynamic> json) {
    return ConversationOwnerModel(
      id: (json['id'] ?? json['objectId'] ?? json['userId'] ?? '').toString(),
      name: (json['name'] ?? json['email'] ?? '').toString(),
    );
  }
}
