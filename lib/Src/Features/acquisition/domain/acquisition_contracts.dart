import 'package:agente_vendas_saas/Src/Shared/models/acquisition_models.dart';

class AcquisitionOverview {
  const AcquisitionOverview({
    required this.metrics,
    required this.accounts,
    required this.campaigns,
    this.nextCursor,
    this.correlationId,
  });

  final AcquisitionMetricsModel metrics;
  final List<AcquisitionAdAccountModel> accounts;
  final List<AcquisitionCampaignModel> campaigns;
  final String? nextCursor;
  final String? correlationId;
}

class AcquisitionMutationResult {
  const AcquisitionMutationResult({
    required this.campaign,
    this.correlationId,
  });

  final AcquisitionCampaignModel campaign;
  final String? correlationId;
}

class AcquisitionAiSuggestion {
  const AcquisitionAiSuggestion({
    required this.headline,
    required this.primaryText,
    required this.description,
    required this.callToAction,
    this.rationale,
    this.warnings = const <String>[],
    this.correlationId,
  });

  final String headline;
  final String primaryText;
  final String description;
  final String callToAction;
  final String? rationale;
  final List<String> warnings;
  final String? correlationId;
}

class GoogleAdsConnectionStatus {
  const GoogleAdsConnectionStatus({
    required this.connected,
    required this.status,
    this.accountName,
    this.customerId,
    this.correlationId,
  });

  final bool connected;
  final String status;
  final String? accountName;
  final String? customerId;
  final String? correlationId;
}

class GoogleAdsOAuthStart {
  const GoogleAdsOAuthStart({
    required this.authorizationUrl,
    this.correlationId,
  });

  final String authorizationUrl;
  final String? correlationId;
}

abstract final class AcquisitionCampaignStatus {
  static const String draft = 'draft';
  static const String preparing = 'preparing';
  static const String review = 'review';
  static const String active = 'active';
  static const String paused = 'paused';
  static const String finished = 'finished';
  static const String authorizationError = 'authorization_error';
  static const String publicationError = 'publication_error';
  static const String paymentIssue = 'payment_issue';

  static const List<String> values = <String>[
    draft,
    preparing,
    review,
    active,
    paused,
    finished,
    authorizationError,
    publicationError,
    paymentIssue,
  ];
}

abstract final class AcquisitionCampaignAction {
  static const String pause = 'pause';
  static const String resume = 'resume';
  static const String duplicate = 'duplicate';
  static const String finish = 'finish';
}
