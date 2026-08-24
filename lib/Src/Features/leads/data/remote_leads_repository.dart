import 'package:agente_vendas_saas/Src/Core/api/api_result.dart';
import 'package:agente_vendas_saas/Src/Core/http/endpoints.dart';
import 'package:agente_vendas_saas/Src/Core/http/http_manager.dart';
import 'package:agente_vendas_saas/Src/Features/leads/domain/lead_filters.dart';
import 'package:agente_vendas_saas/Src/Features/leads/domain/lead_import_result.dart';
import 'package:agente_vendas_saas/Src/Features/leads/domain/lead_input.dart';
import 'package:agente_vendas_saas/Src/Features/leads/domain/lead_page.dart';
import 'package:agente_vendas_saas/Src/Features/leads/domain/leads_repository.dart';
import 'package:agente_vendas_saas/Src/Shared/models/lead_model.dart';

class RemoteLeadsRepository implements LeadsRepository {
  RemoteLeadsRepository(this._httpManager);

  final HttpManager _httpManager;

  @override
  Future<LeadPage> list({
    required String workspaceId,
    required LeadFilters filters,
    String? cursor,
    int limit = 20,
  }) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.leadsList,
      parameters: <String, dynamic>{
        'workspaceId': workspaceId,
        ...filters.toParameters(),
        if (cursor != null) 'cursor': cursor,
        'limit': limit,
      },
    );

    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data, :final meta) => LeadPage(
          items: _items(data)
              .map((Map<String, dynamic> json) => LeadModel.fromJson(json))
              .toList(growable: false),
          nextCursor: meta.nextCursor ?? data['nextCursor']?.toString(),
          correlationId: meta.correlationId,
        ),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }

  @override
  Future<LeadModel> get({
    required String workspaceId,
    required String leadId,
  }) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.leadsGet,
      parameters: <String, dynamic>{'workspaceId': workspaceId, 'leadId': leadId},
    );
    return _leadFromResult(result);
  }

  @override
  Future<LeadModel> create({
    required String workspaceId,
    required LeadInput input,
  }) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.leadsCreate,
      parameters: <String, dynamic>{
        'workspaceId': workspaceId,
        'lead': input.toJson(),
      },
    );
    return _leadFromResult(result);
  }

  @override
  Future<LeadModel> update({
    required String workspaceId,
    required String leadId,
    required LeadInput input,
  }) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.leadsUpdate,
      parameters: <String, dynamic>{
        'workspaceId': workspaceId,
        'leadId': leadId,
        'changes': input.toJson(),
      },
    );
    return _leadFromResult(result);
  }

  @override
  Future<LeadImportResult> import({
    required String workspaceId,
    required List<Map<String, dynamic>> rows,
  }) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.leadsImport,
      parameters: <String, dynamic>{'workspaceId': workspaceId, 'rows': rows},
    );
    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data) =>
        LeadImportResult.fromJson(data),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }

  static LeadModel _leadFromResult(ApiResult<Map<String, dynamic>> result) {
    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data) => LeadModel.fromJson(
          data['lead'] is Map
              ? Map<String, dynamic>.from(data['lead'] as Map)
              : data,
        ),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }

  static Iterable<Map<String, dynamic>> _items(Map<String, dynamic> data) {
    final raw = data['items'] ?? data['leads'] ?? const <dynamic>[];
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw.whereType<Map>().map(Map<String, dynamic>.from);
  }
}
