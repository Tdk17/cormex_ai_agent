class AcquisitionMetricsModel {
  const AcquisitionMetricsModel({
    required this.activeCampaigns,
    required this.investment,
    required this.leads,
    required this.costPerLead,
    required this.conversions,
    required this.roas,
    this.currency = 'BRL',
  });

  final int activeCampaigns;
  final double investment;
  final int leads;
  final double costPerLead;
  final int conversions;
  final double roas;
  final String currency;

  factory AcquisitionMetricsModel.fromJson(Map<String, dynamic> json) {
    return AcquisitionMetricsModel(
      activeCampaigns: (json['activeCampaigns'] as num?)?.toInt() ?? 0,
      investment: (json['investment'] as num?)?.toDouble() ?? 0,
      leads: (json['leads'] as num?)?.toInt() ?? 0,
      costPerLead: (json['costPerLead'] as num?)?.toDouble() ?? 0,
      conversions: (json['conversions'] as num?)?.toInt() ?? 0,
      roas: (json['roas'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'BRL',
    );
  }
}

class AcquisitionAdAccountModel {
  const AcquisitionAdAccountModel({
    required this.id,
    required this.provider,
    required this.name,
    required this.status,
    this.externalAccountId,
    this.currency = 'BRL',
    this.lastSyncAt,
  });

  final String id;
  final String provider;
  final String name;
  final String status;
  final String? externalAccountId;
  final String currency;
  final DateTime? lastSyncAt;

  bool get isConnected => status == 'connected' || status == 'active';
  bool get requiresAttention => const <String>{
        'authorization_error',
        'permission_error',
        'payment_issue',
        'expired',
      }.contains(status);

  factory AcquisitionAdAccountModel.fromJson(Map<String, dynamic> json) {
    return AcquisitionAdAccountModel(
      id: (json['id'] ?? json['objectId'] ?? '').toString(),
      provider: json['provider']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Conta de anúncios',
      status: json['status']?.toString() ?? 'disconnected',
      externalAccountId: json['externalAccountId']?.toString(),
      currency: json['currency']?.toString() ?? 'BRL',
      lastSyncAt: DateTime.tryParse(json['lastSyncAt']?.toString() ?? ''),
    );
  }
}

class AcquisitionCampaignModel {
  const AcquisitionCampaignModel({
    required this.id,
    required this.name,
    required this.productName,
    required this.objective,
    required this.channels,
    required this.status,
    required this.budgetType,
    required this.budgetAmount,
    required this.investment,
    required this.leads,
    required this.conversions,
    required this.currency,
    required this.updatedAt,
    required this.version,
    this.startAt,
    this.endAt,
    this.providerCampaignIds = const <String, String>{},
    this.input,
  });

  final String id;
  final String name;
  final String productName;
  final String objective;
  final List<String> channels;
  final String status;
  final String budgetType;
  final double budgetAmount;
  final double investment;
  final int leads;
  final int conversions;
  final String currency;
  final DateTime? startAt;
  final DateTime? endAt;
  final DateTime updatedAt;
  final int version;
  final Map<String, String> providerCampaignIds;
  final Map<String, dynamic>? input;

  bool get canEdit => const <String>{
        'draft',
        'preparing',
        'review',
        'paused',
        'publication_error',
      }.contains(status);
  bool get canPublish => status == 'draft' || status == 'review';
  bool get canPause => status == 'active';
  bool get canResume => status == 'paused';
  bool get canFinish => !const <String>{'finished', 'draft'}.contains(status);

  factory AcquisitionCampaignModel.fromJson(Map<String, dynamic> json) {
    final rawInput = json['input'] ?? json['configuration'];
    final rawProviderIds = json['providerCampaignIds'];
    return AcquisitionCampaignModel(
      id: (json['id'] ?? json['objectId'] ?? '').toString(),
      name: json['name']?.toString() ?? '',
      productName: (json['productName'] ??
              (rawInput is Map ? rawInput['productName'] : null) ??
              '')
          .toString(),
      objective: json['objective']?.toString() ?? '',
      channels: (json['channels'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic item) => item.toString())
          .where((String item) => item.isNotEmpty)
          .toList(growable: false),
      status: json['status']?.toString() ?? 'draft',
      budgetType: json['budgetType']?.toString() ?? 'daily',
      budgetAmount: (json['budgetAmount'] as num?)?.toDouble() ?? 0,
      investment: (json['investment'] as num?)?.toDouble() ?? 0,
      leads: (json['leads'] as num?)?.toInt() ?? 0,
      conversions: (json['conversions'] as num?)?.toInt() ?? 0,
      currency: json['currency']?.toString() ?? 'BRL',
      startAt: DateTime.tryParse(json['startAt']?.toString() ?? ''),
      endAt: DateTime.tryParse(json['endAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      version: (json['version'] as num?)?.toInt() ?? 0,
      providerCampaignIds: rawProviderIds is Map
          ? rawProviderIds.map(
              (dynamic key, dynamic value) =>
                  MapEntry(key.toString(), value.toString()),
            )
          : const <String, String>{},
      input: rawInput is Map
          ? Map<String, dynamic>.from(rawInput)
          : null,
    );
  }
}
