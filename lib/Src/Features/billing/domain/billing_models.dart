class BillingOverviewModel {
  const BillingOverviewModel({
    required this.plan,
    required this.usage,
    this.warnings = const <BillingWarningModel>[],
  });

  final BillingPlanModel? plan;
  final BillingUsageModel usage;
  final List<BillingWarningModel> warnings;

  factory BillingOverviewModel.fromJson(Map<String, dynamic> json) {
    final planJson = json['plan'] is Map
        ? Map<String, dynamic>.from(json['plan'] as Map)
        : null;
    final usageJson = json['usage'] is Map
        ? Map<String, dynamic>.from(json['usage'] as Map)
        : const <String, dynamic>{};
    final warningsJson = json['warnings'] is List
        ? json['warnings'] as List<dynamic>
        : const <dynamic>[];

    return BillingOverviewModel(
      plan: planJson == null ? null : BillingPlanModel.fromJson(planJson),
      usage: BillingUsageModel.fromJson(usageJson),
      warnings: warningsJson
          .whereType<Map>()
          .map(
            (Map item) => BillingWarningModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false),
    );
  }
}

class BillingPlanModel {
  const BillingPlanModel({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.status,
    required this.features,
    this.billingCycle,
    this.renewsAt,
  });

  final String id;
  final String name;
  final double price;
  final String currency;
  final String status;
  final String? billingCycle;
  final DateTime? renewsAt;
  final List<String> features;

  factory BillingPlanModel.fromJson(Map<String, dynamic> json) {
    return BillingPlanModel(
      id: (json['id'] ?? json['objectId'] ?? '').toString(),
      name: json['name']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'BRL',
      status: json['status']?.toString() ?? 'unknown',
      billingCycle: json['billingCycle']?.toString(),
      renewsAt: DateTime.tryParse(json['renewsAt']?.toString() ?? ''),
      features: (json['features'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic item) => item.toString())
          .toList(growable: false),
    );
  }
}

class BillingUsageModel {
  const BillingUsageModel({
    required this.aiMessagesUsed,
    required this.aiMessagesLimit,
    required this.leadsUsed,
    required this.leadsLimit,
    required this.membersUsed,
    required this.membersLimit,
    this.storageBytesUsed = 0,
    this.storageBytesLimit = 0,
    this.campaignsActive = 0,
    this.campaignsActiveLimit = 0,
    this.periodStart,
    this.periodEnd,
  });

  final int aiMessagesUsed;
  final int aiMessagesLimit;
  final int leadsUsed;
  final int leadsLimit;
  final int membersUsed;
  final int membersLimit;
  final int storageBytesUsed;
  final int storageBytesLimit;
  final int campaignsActive;
  final int campaignsActiveLimit;
  final DateTime? periodStart;
  final DateTime? periodEnd;

  factory BillingUsageModel.fromJson(Map<String, dynamic> json) {
    return BillingUsageModel(
      aiMessagesUsed: (json['aiMessagesUsed'] as num?)?.toInt() ?? 0,
      aiMessagesLimit: (json['aiMessagesLimit'] as num?)?.toInt() ?? 0,
      leadsUsed: (json['leadsUsed'] as num?)?.toInt() ?? 0,
      leadsLimit: (json['leadsLimit'] as num?)?.toInt() ?? 0,
      membersUsed: (json['membersUsed'] as num?)?.toInt() ?? 0,
      membersLimit: (json['membersLimit'] as num?)?.toInt() ?? 0,
      storageBytesUsed: (json['storageBytesUsed'] as num?)?.toInt() ?? 0,
      storageBytesLimit: (json['storageBytesLimit'] as num?)?.toInt() ?? 0,
      campaignsActive: (json['campaignsActive'] as num?)?.toInt() ?? 0,
      campaignsActiveLimit:
          (json['campaignsActiveLimit'] as num?)?.toInt() ?? 0,
      periodStart: DateTime.tryParse(json['periodStart']?.toString() ?? ''),
      periodEnd: DateTime.tryParse(json['periodEnd']?.toString() ?? ''),
    );
  }
}

class BillingWarningModel {
  const BillingWarningModel({
    required this.metric,
    required this.level,
    required this.message,
    required this.percentage,
  });

  final String metric;
  final String level;
  final String message;
  final double percentage;

  factory BillingWarningModel.fromJson(Map<String, dynamic> json) {
    return BillingWarningModel(
      metric: json['metric']?.toString() ?? '',
      level: json['level']?.toString() ?? 'info',
      message: json['message']?.toString() ?? '',
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
    );
  }
}
