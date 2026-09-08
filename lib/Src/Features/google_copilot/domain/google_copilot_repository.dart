import 'google_copilot_models.dart';

abstract class GoogleCopilotRepository {
  Future<GoogleCopilotConnection> connection({required String workspaceId});

  Future<Uri> startOAuth({
    required String workspaceId,
    required String returnUrl,
  });

  Future<void> saveProperties({
    required String workspaceId,
    String? googleAdsCustomerId,
    String? ga4PropertyId,
    String? searchConsoleSiteUrl,
  });

  Future<GoogleCopilotKpis> dashboard({
    required String workspaceId,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<void> savePolicy({
    required String workspaceId,
    required GoogleCopilotPolicy policy,
  });
}
