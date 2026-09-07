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
    this.customerId,
    this.accountId,
    this.opportunityId,
    this.lastActivityAt,
    this.nextActionAt,
    this.campaignId,
    this.utmSource,
    this.utmCampaign,
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
  final String? customerId;
  final String? accountId;
  final String? opportunityId;
  final DateTime? lastActivityAt;
  final DateTime? nextActionAt;
  final String? campaignId;
  final String? utmSource;
  final String? utmCampaign;
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
      lastContactAt: _date(json['lastContactAt']),
      customerId: json['customerId']?.toString(),
      accountId: json['accountId']?.toString(),
      opportunityId: json['opportunityId']?.toString(),
      lastActivityAt: _date(json['lastActivityAt']),
      nextActionAt: _date(json['nextActionAt']),
      campaignId: json['campaignId']?.toString(),
      utmSource: json['utmSource']?.toString(),
      utmCampaign: json['utmCampaign']?.toString(),
      createdAt: _date(json['createdAt']) ?? DateTime.now(),
      updatedAt: _date(json['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'workspaceId': workspaceId,
      'name': name,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (company != null) 'company': company,
      'source': source,
      'status': status,
      'tags': tags,
      if (ownerId != null) 'ownerId': ownerId,
      'score': score,
      if (lastContactAt != null)
        'lastContactAt': lastContactAt!.toIso8601String(),
      if (customerId != null) 'customerId': customerId,
      if (accountId != null) 'accountId': accountId,
      if (opportunityId != null) 'opportunityId': opportunityId,
      if (lastActivityAt != null)
        'lastActivityAt': lastActivityAt!.toIso8601String(),
      if (nextActionAt != null) 'nextActionAt': nextActionAt!.toIso8601String(),
      if (campaignId != null) 'campaignId': campaignId,
      if (utmSource != null) 'utmSource': utmSource,
      if (utmCampaign != null) 'utmCampaign': utmCampaign,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static DateTime? _date(dynamic value) {
    if (value is Map && value['iso'] != null) {
      return DateTime.tryParse(value['iso'].toString());
    }
    return DateTime.tryParse(value?.toString() ?? '');
  }
}
