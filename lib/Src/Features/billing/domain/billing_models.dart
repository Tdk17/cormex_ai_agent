enum BillingCycle {
  monthly('monthly'),
  yearly('yearly');

  const BillingCycle(this.apiValue);
  final String apiValue;
}

enum BillingPaymentMethod {
  pix('pix', 'PIX'),
  creditCard('credit_card', 'Cartão de crédito'),
  boleto('boleto', 'Boleto');

  const BillingPaymentMethod(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static BillingPaymentMethod? fromApi(String value) {
    for (final method in values) {
      if (method.apiValue == value) return method;
    }
    return null;
  }
}

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

class BillingCatalogModel {
  const BillingCatalogModel({
    required this.plans,
    required this.paymentMethods,
    this.yearlyDiscountLabel,
  });

  final List<BillingCatalogPlanModel> plans;
  final List<BillingPaymentMethod> paymentMethods;
  final String? yearlyDiscountLabel;

  factory BillingCatalogModel.fromJson(Map<String, dynamic> json) {
    final rawPlans = json['plans'] is List
        ? json['plans'] as List<dynamic>
        : const <dynamic>[];
    final rawMethods = json['paymentMethods'] is List
        ? json['paymentMethods'] as List<dynamic>
        : const <dynamic>[];

    return BillingCatalogModel(
      plans: rawPlans
          .whereType<Map>()
          .map(
            (Map item) => BillingCatalogPlanModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false),
      paymentMethods: rawMethods
          .map((dynamic item) =>
              BillingPaymentMethod.fromApi(item.toString()))
          .whereType<BillingPaymentMethod>()
          .toList(growable: false),
      yearlyDiscountLabel: json['yearlyDiscountLabel']?.toString(),
    );
  }
}

class BillingCatalogPlanModel {
  const BillingCatalogPlanModel({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.currency,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.features,
    required this.paymentMethods,
    this.badge,
    this.recommended = false,
    this.active = true,
  });

  final String id;
  final String code;
  final String name;
  final String description;
  final String currency;
  final double monthlyPrice;
  final double yearlyPrice;
  final List<String> features;
  final List<BillingPaymentMethod> paymentMethods;
  final String? badge;
  final bool recommended;
  final bool active;

  double priceFor(BillingCycle cycle) =>
      cycle == BillingCycle.yearly ? yearlyPrice : monthlyPrice;

  double monthlyEquivalentFor(BillingCycle cycle) => cycle == BillingCycle.yearly
      ? yearlyPrice / 12
      : monthlyPrice;

  factory BillingCatalogPlanModel.fromJson(Map<String, dynamic> json) {
    final rawMethods = json['paymentMethods'] is List
        ? json['paymentMethods'] as List<dynamic>
        : const <dynamic>[];
    return BillingCatalogPlanModel(
      id: (json['id'] ?? json['objectId'] ?? '').toString(),
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      currency: json['currency']?.toString() ?? 'BRL',
      monthlyPrice: (json['monthlyPrice'] as num?)?.toDouble() ?? 0,
      yearlyPrice: (json['yearlyPrice'] as num?)?.toDouble() ?? 0,
      badge: json['badge']?.toString(),
      recommended: json['recommended'] == true,
      active: json['active'] != false,
      features: (json['features'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic item) => item.toString())
          .toList(growable: false),
      paymentMethods: rawMethods
          .map((dynamic item) =>
              BillingPaymentMethod.fromApi(item.toString()))
          .whereType<BillingPaymentMethod>()
          .toList(growable: false),
    );
  }
}

class BillingCheckoutModel {
  const BillingCheckoutModel({
    required this.id,
    required this.status,
    required this.planId,
    required this.billingCycle,
    required this.paymentMethod,
    this.checkoutUrl,
    this.pixCopyPaste,
    this.pixQrCodeBase64,
    this.boletoUrl,
    this.boletoBarcode,
    this.expiresAt,
  });

  final String id;
  final String status;
  final String planId;
  final String billingCycle;
  final String paymentMethod;
  final String? checkoutUrl;
  final String? pixCopyPaste;
  final String? pixQrCodeBase64;
  final String? boletoUrl;
  final String? boletoBarcode;
  final DateTime? expiresAt;

  factory BillingCheckoutModel.fromJson(Map<String, dynamic> json) {
    return BillingCheckoutModel(
      id: (json['id'] ?? json['checkoutId'] ?? json['objectId'] ?? '').toString(),
      status: json['status']?.toString() ?? 'pending',
      planId: json['planId']?.toString() ?? '',
      billingCycle: json['billingCycle']?.toString() ?? '',
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      checkoutUrl: json['checkoutUrl']?.toString(),
      pixCopyPaste: json['pixCopyPaste']?.toString(),
      pixQrCodeBase64: json['pixQrCodeBase64']?.toString(),
      boletoUrl: json['boletoUrl']?.toString(),
      boletoBarcode: json['boletoBarcode']?.toString(),
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? ''),
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
