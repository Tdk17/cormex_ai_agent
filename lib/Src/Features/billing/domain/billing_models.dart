class BillingOverviewModel {
  const BillingOverviewModel({
    required this.plan,
    required this.usage,
    required this.entitlement,
    this.warnings = const <BillingWarningModel>[],
    this.trialDays = 7,
  });

  final BillingPlanModel? plan;
  final BillingUsageModel usage;
  final BillingEntitlementModel entitlement;
  final List<BillingWarningModel> warnings;
  final int trialDays;

  factory BillingOverviewModel.fromJson(Map<String, dynamic> json) {
    final planJson = json['plan'] is Map
        ? Map<String, dynamic>.from(json['plan'] as Map)
        : null;
    final usageJson = json['usage'] is Map
        ? Map<String, dynamic>.from(json['usage'] as Map)
        : const <String, dynamic>{};
    final entitlementJson = json['entitlement'] is Map
        ? Map<String, dynamic>.from(json['entitlement'] as Map)
        : const <String, dynamic>{};
    final warningsJson = json['warnings'] is List
        ? json['warnings'] as List<dynamic>
        : const <dynamic>[];

    return BillingOverviewModel(
      plan: planJson == null ? null : BillingPlanModel.fromJson(planJson),
      usage: BillingUsageModel.fromJson(usageJson),
      entitlement: BillingEntitlementModel.fromJson(entitlementJson),
      trialDays: (json['trialDays'] as num?)?.toInt() ?? 7,
      warnings: warningsJson
          .whereType<Map>()
          .map((Map item) => BillingWarningModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false),
    );
  }

  BillingOverviewModel copyWith({BillingUsageModel? usage}) => BillingOverviewModel(
        plan: plan,
        usage: usage ?? this.usage,
        entitlement: entitlement,
        warnings: warnings,
        trialDays: trialDays,
      );
}

class BillingEntitlementModel {
  const BillingEntitlementModel({
    required this.status,
    required this.allowed,
    required this.mode,
    this.trialEndsAt,
    this.renewsAt,
    this.daysRemaining,
  });

  final String status;
  final bool allowed;
  final String mode;
  final DateTime? trialEndsAt;
  final DateTime? renewsAt;
  final int? daysRemaining;

  bool get isTrial => status == 'trial';
  bool get isActive => status == 'active' || status == 'grandfathered';
  bool get isGrandfathered => status == 'grandfathered';
  bool get requiresSubscription => !allowed;

  factory BillingEntitlementModel.fromJson(Map<String, dynamic> json) {
    return BillingEntitlementModel(
      status: json['status']?.toString() ?? 'unknown',
      allowed: json['allowed'] == true,
      mode: json['mode']?.toString() ?? 'subscription',
      trialEndsAt: DateTime.tryParse(json['trialEndsAt']?.toString() ?? ''),
      renewsAt: DateTime.tryParse(json['renewsAt']?.toString() ?? ''),
      daysRemaining: (json['daysRemaining'] as num?)?.toInt(),
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
    this.limits = const <String, dynamic>{},
  });

  final String id;
  final String name;
  final double price;
  final String currency;
  final String status;
  final String? billingCycle;
  final DateTime? renewsAt;
  final List<String> features;
  final Map<String, dynamic> limits;

  factory BillingPlanModel.fromJson(Map<String, dynamic> json) {
    return BillingPlanModel(
      id: (json['code'] ?? json['id'] ?? json['objectId'] ?? '').toString(),
      name: json['name']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'BRL',
      status: json['status']?.toString() ?? 'available',
      billingCycle: json['billingCycle']?.toString(),
      renewsAt: DateTime.tryParse(json['renewsAt']?.toString() ?? ''),
      features: (json['features'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic item) => item.toString())
          .toList(growable: false),
      limits: json['limits'] is Map
          ? Map<String, dynamic>.from(json['limits'] as Map)
          : const <String, dynamic>{},
    );
  }
}

class BillingCatalogModel {
  const BillingCatalogModel({required this.items, required this.trialDays});

  final List<BillingPlanModel> items;
  final int trialDays;

  factory BillingCatalogModel.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] as List<dynamic>? ?? const <dynamic>[];
    return BillingCatalogModel(
      items: raw
          .whereType<Map>()
          .map((item) => BillingPlanModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false),
      trialDays: (json['trialDays'] as num?)?.toInt() ?? 7,
    );
  }
}

class BillingCheckoutModel {
  const BillingCheckoutModel({
    required this.checkoutUrl,
    required this.status,
    required this.plan,
  });

  final String checkoutUrl;
  final String status;
  final BillingPlanModel plan;

  factory BillingCheckoutModel.fromJson(Map<String, dynamic> json) {
    return BillingCheckoutModel(
      checkoutUrl: json['checkoutUrl']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      plan: BillingPlanModel.fromJson(
        json['plan'] is Map
            ? Map<String, dynamic>.from(json['plan'] as Map)
            : const <String, dynamic>{},
      ),
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
    int current(String nested, String flat) {
      final value = json[nested];
      if (value is Map) return (value['current'] as num?)?.toInt() ?? 0;
      return (json[flat] as num?)?.toInt() ?? 0;
    }

    int limit(String nested, String flat) {
      final value = json[nested];
      if (value is Map) return (value['limit'] as num?)?.toInt() ?? 0;
      return (json[flat] as num?)?.toInt() ?? 0;
    }

    final period = json['period'] is Map
        ? Map<String, dynamic>.from(json['period'] as Map)
        : const <String, dynamic>{};

    return BillingUsageModel(
      aiMessagesUsed: current('messages', 'aiMessagesUsed'),
      aiMessagesLimit: limit('messages', 'aiMessagesLimit'),
      leadsUsed: current('leads', 'leadsUsed'),
      leadsLimit: limit('leads', 'leadsLimit'),
      membersUsed: current('teamMembers', 'membersUsed'),
      membersLimit: limit('teamMembers', 'membersLimit'),
      storageBytesUsed: (json['storageBytesUsed'] as num?)?.toInt() ?? 0,
      storageBytesLimit: (json['storageBytesLimit'] as num?)?.toInt() ?? 0,
      campaignsActive: current('campaigns', 'campaignsActive'),
      campaignsActiveLimit: limit('campaigns', 'campaignsActiveLimit'),
      periodStart: DateTime.tryParse((json['periodStart'] ?? period['startAt'])?.toString() ?? ''),
      periodEnd: DateTime.tryParse((json['periodEnd'] ?? period['endAt'])?.toString() ?? ''),
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
