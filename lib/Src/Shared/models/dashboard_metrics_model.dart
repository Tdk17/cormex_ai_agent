class DashboardMetricsModel {
  const DashboardMetricsModel({
    required this.totalLeads,
    required this.activeConversations,
    required this.qualifiedLeads,
    required this.openOpportunities,
    required this.conversions,
    required this.conversionRate,
    required this.funnel,
  });

  final int totalLeads;
  final int activeConversations;
  final int qualifiedLeads;
  final int openOpportunities;
  final int conversions;
  final double conversionRate;
  final Map<String, int> funnel;

  factory DashboardMetricsModel.fromJson(Map<String, dynamic> json) {
    final funnelData = json['funnel'] is Map
        ? Map<String, dynamic>.from(json['funnel'] as Map)
        : const <String, dynamic>{};
    return DashboardMetricsModel(
      totalLeads: (json['totalLeads'] as num?)?.toInt() ?? 0,
      activeConversations: (json['activeConversations'] as num?)?.toInt() ?? 0,
      qualifiedLeads: (json['qualifiedLeads'] as num?)?.toInt() ?? 0,
      openOpportunities: (json['openOpportunities'] as num?)?.toInt() ?? 0,
      conversions: (json['conversions'] as num?)?.toInt() ?? 0,
      conversionRate: (json['conversionRate'] as num?)?.toDouble() ?? 0,
      funnel: funnelData.map(
        (String key, dynamic value) => MapEntry(key, (value as num?)?.toInt() ?? 0),
      ),
    );
  }
}
