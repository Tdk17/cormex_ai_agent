class CustomerModel {
  const CustomerModel({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.email,
    this.phone,
    this.document,
    this.ownerId,
    this.source,
    this.tags = const <String>[],
  });

  final String id;
  final String workspaceId;
  final String name;
  final String? email;
  final String? phone;
  final String? document;
  final String status;
  final String? ownerId;
  final String? source;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: (json['id'] ?? json['objectId'] ?? '').toString(),
      workspaceId: json['workspaceId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      document: json['document']?.toString(),
      status: json['status']?.toString() ?? 'active',
      ownerId: json['ownerId']?.toString(),
      source: json['source']?.toString(),
      tags: _stringList(json['tags']),
      createdAt: _date(json['createdAt']) ?? DateTime.now(),
      updatedAt: _date(json['updatedAt']) ?? DateTime.now(),
    );
  }
}

class AccountModel {
  const AccountModel({
    required this.id,
    required this.workspaceId,
    required this.name,
    this.legalName,
    this.document,
    this.website,
    this.phone,
    this.address,
    this.ownerId,
    this.tags = const <String>[],
  });

  final String id;
  final String workspaceId;
  final String name;
  final String? legalName;
  final String? document;
  final String? website;
  final String? phone;
  final String? address;
  final String? ownerId;
  final List<String> tags;

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: (json['id'] ?? json['objectId'] ?? '').toString(),
      workspaceId: json['workspaceId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      legalName: json['legalName']?.toString(),
      document: json['document']?.toString(),
      website: json['website']?.toString(),
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      ownerId: json['ownerId']?.toString(),
      tags: _stringList(json['tags']),
    );
  }
}

class ActivityModel {
  const ActivityModel({
    required this.id,
    required this.workspaceId,
    required this.type,
    required this.title,
    required this.status,
    required this.dueAt,
    this.description,
    this.completedAt,
    this.ownerId,
    this.leadId,
    this.customerId,
    this.accountId,
    this.opportunityId,
  });

  final String id;
  final String workspaceId;
  final String type;
  final String title;
  final String? description;
  final DateTime dueAt;
  final DateTime? completedAt;
  final String status;
  final String? ownerId;
  final String? leadId;
  final String? customerId;
  final String? accountId;
  final String? opportunityId;

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: (json['id'] ?? json['objectId'] ?? '').toString(),
      workspaceId: json['workspaceId']?.toString() ?? '',
      type: json['type']?.toString() ?? 'task',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      dueAt: _date(json['dueAt']) ?? DateTime.now(),
      completedAt: _date(json['completedAt']),
      status: json['status']?.toString() ?? 'pending',
      ownerId: json['ownerId']?.toString(),
      leadId: json['leadId']?.toString(),
      customerId: json['customerId']?.toString(),
      accountId: json['accountId']?.toString(),
      opportunityId: json['opportunityId']?.toString(),
    );
  }
}

class CrmTimelineEventModel {
  const CrmTimelineEventModel({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.eventType,
    required this.title,
    required this.occurredAt,
    this.metadata = const <String, dynamic>{},
    this.actorId,
  });

  final String id;
  final String entityType;
  final String entityId;
  final String eventType;
  final String title;
  final Map<String, dynamic> metadata;
  final String? actorId;
  final DateTime occurredAt;

  factory CrmTimelineEventModel.fromJson(Map<String, dynamic> json) {
    return CrmTimelineEventModel(
      id: (json['id'] ?? json['objectId'] ?? '').toString(),
      entityType: json['entityType']?.toString() ?? '',
      entityId: json['entityId']?.toString() ?? '',
      eventType: json['eventType']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : const <String, dynamic>{},
      actorId: json['actorId']?.toString(),
      occurredAt: _date(json['occurredAt']) ?? DateTime.now(),
    );
  }
}

List<String> _stringList(dynamic value) {
  return (value as List<dynamic>? ?? const <dynamic>[])
      .map((dynamic item) => item.toString())
      .toList(growable: false);
}

DateTime? _date(dynamic value) {
  if (value is Map && value['iso'] != null) {
    return DateTime.tryParse(value['iso'].toString());
  }
  return DateTime.tryParse(value?.toString() ?? '');
}
