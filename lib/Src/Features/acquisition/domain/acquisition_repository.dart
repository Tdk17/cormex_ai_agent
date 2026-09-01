import 'dart:typed_data';

import 'package:agente_vendas_saas/Src/Features/acquisition/domain/acquisition_campaign_input.dart';
import 'package:agente_vendas_saas/Src/Features/acquisition/domain/acquisition_contracts.dart';
import 'package:agente_vendas_saas/Src/Shared/models/acquisition_models.dart';

abstract interface class AcquisitionRepository {
  Future<AcquisitionOverview> overview({
    required String workspaceId,
    required String period,
    String? channel,
    String? status,
    String? cursor,
  });

  Future<AcquisitionCampaignModel> getCampaign({
    required String workspaceId,
    required String campaignId,
  });

  Future<AcquisitionMutationResult> upsertCampaign({
    required String workspaceId,
    required AcquisitionCampaignInput input,
    required String clientRequestId,
    String? campaignId,
  });

  Future<AcquisitionMutationResult> publishCampaign({
    required String workspaceId,
    required String campaignId,
    required int expectedVersion,
    required String clientRequestId,
  });

  Future<AcquisitionMutationResult> campaignAction({
    required String workspaceId,
    required String campaignId,
    required String action,
    required int expectedVersion,
    required String clientRequestId,
  });

  Future<AcquisitionAiSuggestion> suggestCreative({
    required String workspaceId,
    required AcquisitionCampaignInput input,
    required String clientRequestId,
  });

  Future<String> uploadCampaignMedia({
    required String workspaceId,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
    void Function(int sent, int total)? onSendProgress,
  });
}
