import 'dart:typed_data';

import 'package:agente_vendas_saas/Src/Core/api/api_exception.dart';
import 'package:agente_vendas_saas/Src/Core/api/api_result.dart';
import 'package:agente_vendas_saas/Src/Core/http/endpoints.dart';
import 'package:agente_vendas_saas/Src/Core/http/http_manager.dart';
import 'package:agente_vendas_saas/Src/Features/acquisition/domain/acquisition_campaign_input.dart';
import 'package:agente_vendas_saas/Src/Features/acquisition/domain/acquisition_contracts.dart';
import 'package:agente_vendas_saas/Src/Features/acquisition/domain/acquisition_repository.dart';
import 'package:agente_vendas_saas/Src/Shared/models/acquisition_models.dart';

class RemoteAcquisitionRepository implements AcquisitionRepository {
  RemoteAcquisitionRepository(this._httpManager);

  final HttpManager _httpManager;

  @override
  Future<AcquisitionOverview> overview({
    required String workspaceId,
    required String period,
    String? channel,
    String? status,
    String? cursor,
  }) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.acquisitionOverview,
      parameters: <String, dynamic>{
        'workspaceId': workspaceId,
        'period': period,
        if (channel != null) 'channel': channel,
        if (status != null) 'status': status,
        if (cursor != null) 'cursor': cursor,
        'limit': 20,
      },
    );
    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data, :final meta) =>
        AcquisitionOverview(
          metrics: AcquisitionMetricsModel.fromJson(_map(data['metrics'])),
          accounts: _maps(data['accounts'])
              .map(AcquisitionAdAccountModel.fromJson)
              .toList(growable: false),
          campaigns: _maps(data['campaigns'] ?? data['items'])
              .map(AcquisitionCampaignModel.fromJson)
              .toList(growable: false),
          nextCursor: meta.nextCursor ?? data['nextCursor']?.toString(),
          correlationId: meta.correlationId,
        ),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }

  @override
  Future<AcquisitionCampaignModel> getCampaign({
    required String workspaceId,
    required String campaignId,
  }) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.acquisitionCampaignGet,
      parameters: <String, dynamic>{
        'workspaceId': workspaceId,
        'campaignId': campaignId,
      },
    );
    return _campaign(result).campaign;
  }

  @override
  Future<AcquisitionMutationResult> upsertCampaign({
    required String workspaceId,
    required AcquisitionCampaignInput input,
    required String clientRequestId,
    String? campaignId,
  }) {
    return _mutate(
      Endpoints.acquisitionCampaignUpsert,
      <String, dynamic>{
        'workspaceId': workspaceId,
        if (campaignId != null) 'campaignId': campaignId,
        'campaign': input.toJson(),
        'clientRequestId': clientRequestId,
      },
    );
  }

  @override
  Future<AcquisitionMutationResult> publishCampaign({
    required String workspaceId,
    required String campaignId,
    required int expectedVersion,
    required String clientRequestId,
  }) {
    return _mutate(
      Endpoints.acquisitionCampaignPublish,
      <String, dynamic>{
        'workspaceId': workspaceId,
        'campaignId': campaignId,
        'expectedVersion': expectedVersion,
        'clientRequestId': clientRequestId,
      },
    );
  }

  @override
  Future<AcquisitionMutationResult> campaignAction({
    required String workspaceId,
    required String campaignId,
    required String action,
    required int expectedVersion,
    required String clientRequestId,
  }) {
    return _mutate(
      Endpoints.acquisitionCampaignAction,
      <String, dynamic>{
        'workspaceId': workspaceId,
        'campaignId': campaignId,
        'action': action,
        'expectedVersion': expectedVersion,
        'clientRequestId': clientRequestId,
      },
    );
  }

  @override
  Future<AcquisitionAiSuggestion> suggestCreative({
    required String workspaceId,
    required AcquisitionCampaignInput input,
    required String clientRequestId,
  }) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.acquisitionAiSuggest,
      parameters: <String, dynamic>{
        'workspaceId': workspaceId,
        'campaign': input.toJson(),
        'section': 'creative',
        'clientRequestId': clientRequestId,
      },
    );
    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data, :final meta) => () {
          final suggestion = _map(data['suggestion'] ?? data);
          return AcquisitionAiSuggestion(
            headline: suggestion['headline']?.toString() ?? '',
            primaryText: suggestion['primaryText']?.toString() ?? '',
            description: suggestion['description']?.toString() ?? '',
            callToAction:
                suggestion['callToAction']?.toString() ?? 'LEARN_MORE',
            rationale: suggestion['rationale']?.toString(),
            warnings: (suggestion['warnings'] as List<dynamic>? ??
                    const <dynamic>[])
                .map((dynamic item) => item.toString())
                .toList(growable: false),
            correlationId: meta.correlationId,
          );
        }(),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }

  @override
  Future<String> uploadCampaignMedia({
    required String workspaceId,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    if (workspaceId.trim().isEmpty) {
      throw const ApiException(
        code: 'WORKSPACE_REQUIRED',
        message: 'Workspace inválido para upload de mídia.',
      );
    }
    final result = await _httpManager.uploadParseFile(
      fileName: 'campaign-${workspaceId.trim()}-$fileName',
      bytes: bytes,
      contentType: contentType,
      onSendProgress: onSendProgress,
    );
    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data) => () {
          final url = data['url']?.toString().trim() ?? '';
          if (url.isEmpty) {
            throw const ApiException(
              code: 'MEDIA_UPLOAD_ERROR',
              message: 'O armazenamento não retornou a URL da mídia.',
            );
          }
          return url;
        }(),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }

  @override
  Future<GoogleAdsConnectionStatus> googleAdsConnectionStatus({
    required String workspaceId,
  }) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.googleAdsConnectionStatus,
      parameters: <String, dynamic>{'workspaceId': workspaceId},
    );
    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data, :final meta) => () {
          final account = _map(data['account']);
          return GoogleAdsConnectionStatus(
            connected: data['connected'] == true,
            status: data['status']?.toString() ??
                (data['connected'] == true ? 'connected' : 'disconnected'),
            accountName: account['name']?.toString() ?? data['accountName']?.toString(),
            customerId: account['customerId']?.toString() ?? data['customerId']?.toString(),
            correlationId: meta.correlationId,
          );
        }(),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }

  @override
  Future<GoogleAdsOAuthStart> startGoogleAdsOAuth({
    required String workspaceId,
    required String returnUrl,
  }) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.googleAdsOAuthStart,
      parameters: <String, dynamic>{
        'workspaceId': workspaceId,
        'returnUrl': returnUrl,
      },
    );
    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data, :final meta) => () {
          final authorizationUrl =
              data['authorizationUrl']?.toString().trim() ?? '';
          if (authorizationUrl.isEmpty) {
            throw const ApiException(
              code: 'GOOGLE_OAUTH_ERROR',
              message: 'A API não retornou a URL de autorização do Google.',
            );
          }
          return GoogleAdsOAuthStart(
            authorizationUrl: authorizationUrl,
            correlationId: meta.correlationId,
          );
        }(),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }

  Future<AcquisitionMutationResult> _mutate(
    String endpoint,
    Map<String, dynamic> parameters,
  ) async {
    final result = await _httpManager.cloudFunction(
      name: endpoint,
      parameters: parameters,
    );
    return _campaign(result);
  }

  static AcquisitionMutationResult _campaign(
    ApiResult<Map<String, dynamic>> result,
  ) {
    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data, :final meta) =>
        AcquisitionMutationResult(
          campaign: AcquisitionCampaignModel.fromJson(
            _map(data['campaign'] ?? data),
          ),
          correlationId: meta.correlationId,
        ),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }

  static Map<String, dynamic> _map(dynamic raw) {
    return raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
  }

  static Iterable<Map<String, dynamic>> _maps(dynamic raw) {
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw.whereType<Map>().map(Map<String, dynamic>.from);
  }
}
