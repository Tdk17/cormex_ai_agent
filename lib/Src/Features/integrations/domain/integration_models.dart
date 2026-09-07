class IntegrationProviders {
  const IntegrationProviders._();

  static const String googleAds = 'google_ads';
  static const String whatsapp = 'whatsapp';
  static const String metaAds = 'meta_ads';
}

class IntegrationStatuses {
  const IntegrationStatuses._();

  static const String disconnected = 'disconnected';
  static const String connecting = 'connecting';
  static const String connected = 'connected';
  static const String authorizationError = 'authorization_error';
  static const String permissionError = 'permission_error';
  static const String paymentIssue = 'payment_issue';
  static const String expired = 'expired';
  static const String disabled = 'disabled';
}

class IntegrationModel {
  const IntegrationModel({
    required this.id,
    required this.provider,
    required this.type,
    required this.status,
    required this.displayName,
    required this.maskedAccount,
    required this.externalAccountId,
    required this.capabilities,
    required this.lastSyncAt,
    required this.requiresAction,
    required this.version,
  });

  final String id;
  final String provider;
  final String type;
  final String status;
  final String? displayName;
  final String? maskedAccount;
  final String? externalAccountId;
  final List<String> capabilities;
  final DateTime? lastSyncAt;
  final bool requiresAction;
  final int? version;

  bool get connected => status == IntegrationStatuses.connected;

  factory IntegrationModel.fromJson(Map<String, dynamic> json) {
    return IntegrationModel(
      id: json['id']?.toString() ?? '',
      provider: json['provider']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      status: json['status']?.toString() ?? IntegrationStatuses.disconnected,
      displayName: _nullableString(json['displayName']),
      maskedAccount: _nullableString(json['maskedAccount']),
      externalAccountId: _nullableString(json['externalAccountId']),
      capabilities: _strings(json['capabilities']),
      lastSyncAt: _date(json['lastSyncAt']),
      requiresAction: json['requiresAction'] == true,
      version: _int(json['version']),
    );
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static List<String> _strings(dynamic value) {
    if (value is! List) return const <String>[];
    return value
        .map((dynamic item) => item?.toString().trim() ?? '')
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static DateTime? _date(dynamic value) {
    if (value is String) return DateTime.tryParse(value);
    if (value is Map) {
      final iso = value['iso']?.toString();
      if (iso != null) return DateTime.tryParse(iso);
    }
    return null;
  }

  static int? _int(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }
}

class IntegrationListResult {
  const IntegrationListResult({required this.items, this.correlationId});

  final List<IntegrationModel> items;
  final String? correlationId;
}

class IntegrationCommandResult {
  const IntegrationCommandResult({
    required this.status,
    this.authorizationUrl,
    this.expiresAt,
    this.integration,
    this.correlationId,
  });

  final String status;
  final String? authorizationUrl;
  final DateTime? expiresAt;
  final IntegrationModel? integration;
  final String? correlationId;
}
