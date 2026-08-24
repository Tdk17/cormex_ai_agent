class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.leadId,
    required this.leadName,
    required this.channel,
    required this.status,
    required this.agentMode,
    required this.lastMessagePreview,
    required this.unreadCount,
    this.assignedUserId,
    this.lastMessageAt,
  });

  final String id;
  final String leadId;
  final String leadName;
  final String channel;
  final String status;
  final String agentMode;
  final String? assignedUserId;
  final String lastMessagePreview;
  final DateTime? lastMessageAt;
  final int unreadCount;

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final lead = json['lead'] is Map
        ? Map<String, dynamic>.from(json['lead'] as Map)
        : const <String, dynamic>{};
    final lastMessage = json['lastMessage'] is Map
        ? Map<String, dynamic>.from(json['lastMessage'] as Map)
        : const <String, dynamic>{};
    return ConversationModel(
      id: (json['id'] ?? json['objectId'] ?? '').toString(),
      leadId: lead['id']?.toString() ?? json['leadId']?.toString() ?? '',
      leadName: lead['name']?.toString() ?? '',
      channel: json['channel']?.toString() ?? 'whatsapp',
      status: json['status']?.toString() ?? 'open',
      agentMode: json['agentMode']?.toString() ?? 'assist',
      assignedUserId: json['assignedUserId']?.toString(),
      lastMessagePreview: lastMessage['preview']?.toString() ?? '',
      lastMessageAt: DateTime.tryParse(lastMessage['sentAt']?.toString() ?? ''),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
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
  });

  final String id;
  final String conversationId;
  final String direction;
  final String senderType;
  final String type;
  final String content;
  final String status;
  final DateTime sentAt;

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: (json['id'] ?? json['objectId'] ?? '').toString(),
      conversationId: json['conversationId']?.toString() ?? '',
      direction: json['direction']?.toString() ?? 'inbound',
      senderType: json['senderType']?.toString() ?? 'system',
      type: json['type']?.toString() ?? 'text',
      content: json['content']?.toString() ?? '',
      status: json['status']?.toString() ?? 'sent',
      sentAt: DateTime.tryParse(json['sentAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
