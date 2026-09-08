class GoogleCopilotConnection {
  const GoogleCopilotConnection({
    required this.connected,
    this.email,
    this.googleAdsCustomerId,
    this.ga4PropertyId,
    this.searchConsoleSiteUrl,
  });

  final bool connected;
  final String? email;
  final String? googleAdsCustomerId;
  final String? ga4PropertyId;
  final String? searchConsoleSiteUrl;

  factory GoogleCopilotConnection.fromJson(Map<String, dynamic> json) {
    return GoogleCopilotConnection(
      connected: json['connected'] == true,
      email: _text(json['googleEmail'] ?? json['email']),
      googleAdsCustomerId: _text(json['googleAdsCustomerId']),
      ga4PropertyId: _text(json['ga4PropertyId']),
      searchConsoleSiteUrl: _text(json['searchConsoleSiteUrl']),
    );
  }

  static String? _text(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}

class GoogleCopilotKpis {
  const GoogleCopilotKpis({
    required this.googleAds,
    required this.ga4,
    required this.searchConsole,
    required this.warnings,
  });

  final dynamic googleAds;
  final dynamic ga4;
  final dynamic searchConsole;
  final List<String> warnings;

  factory GoogleCopilotKpis.fromJson(Map<String, dynamic> json) {
    return GoogleCopilotKpis(
      googleAds: json['googleAds'],
      ga4: json['ga4'],
      searchConsole: json['searchConsole'],
      warnings: (json['warnings'] is List)
          ? (json['warnings'] as List).map((e) => e.toString()).toList(growable: false)
          : const <String>[],
    );
  }
}

class GoogleCopilotPolicy {
  const GoogleCopilotPolicy({
    required this.maxDailyBudgetMicros,
    required this.maxBudgetChangePercent,
    required this.allowAutoPause,
    required this.allowAutoBudgetChange,
    this.protectedCampaignResourceNames = const <String>[],
  });

  final String maxDailyBudgetMicros;
  final double maxBudgetChangePercent;
  final bool allowAutoPause;
  final bool allowAutoBudgetChange;
  final List<String> protectedCampaignResourceNames;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'maxDailyBudgetMicros': maxDailyBudgetMicros,
        'maxBudgetChangePercent': maxBudgetChangePercent,
        'allowAutoPause': allowAutoPause,
        'allowAutoBudgetChange': allowAutoBudgetChange,
        'protectedCampaignResourceNames': protectedCampaignResourceNames,
      };
}
