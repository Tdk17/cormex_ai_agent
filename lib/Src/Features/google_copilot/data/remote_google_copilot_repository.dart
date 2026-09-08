import 'package:agente_vendas_saas/Src/Core/api/api_result.dart';
import 'package:agente_vendas_saas/Src/Core/http/endpoints.dart';
import 'package:agente_vendas_saas/Src/Core/http/http_manager.dart';
import 'package:agente_vendas_saas/Src/Features/google_copilot/domain/google_copilot_models.dart';
import 'package:agente_vendas_saas/Src/Features/google_copilot/domain/google_copilot_repository.dart';

class RemoteGoogleCopilotRepository implements GoogleCopilotRepository {
  RemoteGoogleCopilotRepository(this._httpManager);

  final HttpManager _httpManager;

  @override
  Future<GoogleCopilotConnection> connection({required String workspaceId}) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.googleCopilotConnection,
      parameters: <String, dynamic>{'workspaceId': workspaceId},
    );
    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data) => GoogleCopilotConnection.fromJson(data),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }

  @override
  Future<Uri> startOAuth({
    required String workspaceId,
    required String returnUrl,
  }) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.googleCopilotOAuthStart,
      parameters: <String, dynamic>{
        'workspaceId': workspaceId,
        'returnUrl': returnUrl,
      },
    );
    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data) => _authorizationUri(data),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }

  @override
  Future<void> saveProperties({
    required String workspaceId,
    String? googleAdsCustomerId,
    String? ga4PropertyId,
    String? searchConsoleSiteUrl,
  }) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.googleCopilotPropertiesUpdate,
      parameters: <String, dynamic>{
        'workspaceId': workspaceId,
        'googleAdsCustomerId': googleAdsCustomerId?.trim(),
        'ga4PropertyId': ga4PropertyId?.trim(),
        'searchConsoleSiteUrl': searchConsoleSiteUrl?.trim(),
      },
    );
    switch (result) {
      case ApiSuccess<Map<String, dynamic>>():
        return;
      case ApiFailure<Map<String, dynamic>>(:final error):
        throw error;
    }
  }

  @override
  Future<GoogleCopilotKpis> dashboard({
    required String workspaceId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.googleCopilotDashboard,
      parameters: <String, dynamic>{
        'workspaceId': workspaceId,
        'startDate': _date(startDate),
        'endDate': _date(endDate),
      },
    );
    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data) => GoogleCopilotKpis.fromJson(data),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }

  @override
  Future<void> savePolicy({
    required String workspaceId,
    required GoogleCopilotPolicy policy,
  }) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.googleCopilotPolicyUpdate,
      parameters: <String, dynamic>{
        'workspaceId': workspaceId,
        ...policy.toJson(),
      },
    );
    switch (result) {
      case ApiSuccess<Map<String, dynamic>>():
        return;
      case ApiFailure<Map<String, dynamic>>(:final error):
        throw error;
    }
  }

  static Uri _authorizationUri(Map<String, dynamic> data) {
    final raw = data['authorizationUrl']?.toString().trim() ?? '';
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme) {
      throw StateError('O backend não retornou uma URL OAuth válida.');
    }
    return uri;
  }

  static String _date(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
