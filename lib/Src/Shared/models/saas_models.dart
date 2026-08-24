class IntegrationModel {
  const IntegrationModel({
    required this.id,
    required this.provider,
    required this.status,
    this.maskedAccount,
    this.lastSyncAt,
  });

  final String id;
  final String provider;
  final String status;
  final String? maskedAccount;
  final DateTime? lastSyncAt;

  factory IntegrationModel.fromJson(Map<String, dynamic> json) {
    return IntegrationModel(
      id: (json['id'] ?? json['objectId'] ?? '').toString(),
      provider: json['provider']?.toString() ?? '',
      status: json['status']?.toString() ?? 'disconnected',
      maskedAccount: json['maskedAccount']?.toString(),
      lastSyncAt: DateTime.tryParse(json['lastSyncAt']?.toString() ?? ''),
    );
  }
}

class UsageModel {
  const UsageModel({
    required this.aiMessagesUsed,
    required this.aiMessagesLimit,
    required this.leadsUsed,
    required this.leadsLimit,
    required this.membersUsed,
    required this.membersLimit,
  });

  final int aiMessagesUsed;
  final int aiMessagesLimit;
  final int leadsUsed;
  final int leadsLimit;
  final int membersUsed;
  final int membersLimit;

  factory UsageModel.fromJson(Map<String, dynamic> json) {
    return UsageModel(
      aiMessagesUsed: (json['aiMessagesUsed'] as num?)?.toInt() ?? 0,
      aiMessagesLimit: (json['aiMessagesLimit'] as num?)?.toInt() ?? 0,
      leadsUsed: (json['leadsUsed'] as num?)?.toInt() ?? 0,
      leadsLimit: (json['leadsLimit'] as num?)?.toInt() ?? 0,
      membersUsed: (json['membersUsed'] as num?)?.toInt() ?? 0,
      membersLimit: (json['membersLimit'] as num?)?.toInt() ?? 0,
    );
  }
}

class PlanModel {
  const PlanModel({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.features,
  });

  final String id;
  final String name;
  final double price;
  final String currency;
  final List<String> features;

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: (json['id'] ?? json['objectId'] ?? '').toString(),
      name: json['name']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'BRL',
      features: (json['features'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic item) => item.toString())
          .toList(growable: false),
    );
  }
}
