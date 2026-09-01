class DashboardMetricsModel {
  const DashboardMetricsModel({
    required this.totalLeads,
    required this.activeConversations,
    required this.qualifiedLeads,
    required this.openOpportunities,
    required this.conversions,
    required this.conversionRate,
    required this.funnel,
    this.changes = const <String, String>{},
    this.recentConversations = const <DashboardConversationPreviewModel>[],
    this.hasConnectedChannel = false,
  });

  final int totalLeads;
  final int activeConversations;
  final int qualifiedLeads;
  final int openOpportunities;
  final int conversions;
  final double conversionRate;
  final Map<String, int> funnel;
  final Map<String, String> changes;
  final List<DashboardConversationPreviewModel> recentConversations;
  final bool hasConnectedChannel;

  bool get isEmpty =>
      totalLeads == 0 &&
      activeConversations == 0 &&
      qualifiedLeads == 0 &&
      openOpportunities == 0 &&
      conversions == 0 &&
      recentConversations.isEmpty;

  factory DashboardMetricsModel.fromJson(Map<String, dynamic> json) {
    final funnelData = json['funnel'] is Map
        ? Map<String, dynamic>.from(json['funnel'] as Map)
        : const <String, dynamic>{};
    final changesData = json['changes'] is Map
        ? Map<String, dynamic>.from(json['changes'] as Map)
        : const <String, dynamic>{};
    final recentData = json['recentConversations'] is List
        ? json['recentConversations'] as List<dynamic>
        : const <dynamic>[];
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
      changes: changesData.map(
        (String key, dynamic value) => MapEntry(key, value?.toString() ?? ''),
      ),
      recentConversations: recentData
          .whereType<Map>()
          .map(
            (Map item) => DashboardConversationPreviewModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .where((DashboardConversationPreviewModel item) => item.id.isNotEmpty)
          .toList(growable: false),
      hasConnectedChannel: json['hasConnectedChannel'] == true,
    );
  }
}

class DashboardConversationPreviewModel {
  const DashboardConversationPreviewModel({
    required this.id,
    required this.leadName,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  final String id;
  final String leadName;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  factory DashboardConversationPreviewModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return DashboardConversationPreviewModel(
      id: (json['id'] ?? json['objectId'] ?? '').toString(),
      leadName: json['leadName']?.toString() ?? '',
      lastMessage: json['lastMessage']?.toString() ?? '',
      lastMessageAt: _date(json['lastMessageAt']),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }

  static DateTime? _date(dynamic value) {
    if (value is Map && value['iso'] != null) {
      return DateTime.tryParse(value['iso'].toString());
    }
    return DateTime.tryParse(value?.toString() ?? '');
  }
}
