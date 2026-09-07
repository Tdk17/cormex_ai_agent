import 'package:agente_vendas_saas/Src/Core/api/api_result.dart';
import 'package:agente_vendas_saas/Src/Core/http/endpoints.dart';
import 'package:agente_vendas_saas/Src/Core/http/http_manager.dart';
import 'package:agente_vendas_saas/Src/Features/integrations/domain/integration_models.dart';
import 'package:agente_vendas_saas/Src/Features/integrations/domain/integrations_repository.dart';

class RemoteIntegrationsRepository implements IntegrationsRepository {
  RemoteIntegrationsRepository(this._httpManager);

  final HttpManager _httpManager;

  @override
  Future<IntegrationListResult> list({
    required String workspaceId,
    String? type,
  }) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.integrationsList,
      parameters: <String, dynamic>{
        'workspaceId': workspaceId,
        if (type != null && type.trim().isNotEmpty) 'type': type.trim(),
      },
    );

    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data, :final meta) =>
        IntegrationListResult(
          items: _maps(data['items'])
              .map(IntegrationModel.fromJson)
              .where((IntegrationModel item) => item.provider.isNotEmpty)
              .toList(growable: false),
          correlationId: meta.correlationId,
        ),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }

  @override
  Future<IntegrationCommandResult> connect({
    required String workspaceId,
    required String provider,
    required String action,
    required String clientRequestId,
    String? returnUrl,
    String? integrationId,
    int? expectedVersion,
  }) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.integrationsConnect,
      parameters: <String, dynamic>{
        'workspaceId': workspaceId,
        'provider': provider,
        'action': action,
        'clientRequestId': clientRequestId,
        if (returnUrl != null && returnUrl.trim().isNotEmpty)
          'returnUrl': returnUrl.trim(),
        if (integrationId != null && integrationId.trim().isNotEmpty)
          'integrationId': integrationId.trim(),
        if (expectedVersion != null) 'expectedVersion': expectedVersion,
      },
    );

    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data, :final meta) =>
        IntegrationCommandResult(
          status: data['status']?.toString() ?? '',
          authorizationUrl: _text(data['authorizationUrl']),
          expiresAt: _date(data['expiresAt']),
          integration: _map(data['integration']) == null
              ? null
              : IntegrationModel.fromJson(_map(data['integration'])!),
          correlationId: meta.correlationId,
        ),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }

  static Iterable<Map<String, dynamic>> _maps(dynamic raw) {
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw.whereType<Map>().map(Map<String, dynamic>.from);
  }

  static Map<String, dynamic>? _map(dynamic raw) {
    return raw is Map ? Map<String, dynamic>.from(raw) : null;
  }

  static String? _text(dynamic raw) {
    final value = raw?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  static DateTime? _date(dynamic raw) {
    if (raw is String) return DateTime.tryParse(raw);
    if (raw is Map) {
      final iso = raw['iso']?.toString();
      if (iso != null) return DateTime.tryParse(iso);
    }
    return null;
  }
}
