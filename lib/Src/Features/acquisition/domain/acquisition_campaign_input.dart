class AcquisitionCampaignInput {
  const AcquisitionCampaignInput({
    required this.name,
    required this.productName,
    required this.productDescription,
    required this.offer,
    required this.productUrl,
    required this.mediaUrls,
    required this.objective,
    required this.channels,
    required this.locations,
    required this.ageMin,
    required this.ageMax,
    required this.interests,
    required this.broadAudience,
    required this.budgetType,
    required this.budgetAmount,
    required this.startAt,
    required this.endAt,
    required this.headline,
    required this.primaryText,
    required this.description,
    required this.callToAction,
    required this.destinationType,
    required this.destinationUrl,
    required this.captureFields,
    required this.consentText,
    required this.initialMessage,
    required this.qualificationQuestions,
    required this.pipelineStageId,
    required this.tags,
    required this.onlyRegisterLead,
    required this.expectedVersion,
  });

  final String name;
  final String productName;
  final String productDescription;
  final String offer;
  final String productUrl;
  final List<String> mediaUrls;
  final String objective;
  final List<String> channels;
  final List<String> locations;
  final int ageMin;
  final int ageMax;
  final List<String> interests;
  final bool broadAudience;
  final String budgetType;
  final double budgetAmount;
  final DateTime? startAt;
  final DateTime? endAt;
  final String headline;
  final String primaryText;
  final String description;
  final String callToAction;
  final String destinationType;
  final String destinationUrl;
  final List<String> captureFields;
  final String consentText;
  final String initialMessage;
  final List<String> qualificationQuestions;
  final String pipelineStageId;
  final List<String> tags;
  final bool onlyRegisterLead;
  final int? expectedVersion;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name.trim(),
        'productName': productName.trim(),
        'productDescription': productDescription.trim(),
        'offer': offer.trim(),
        'productUrl': productUrl.trim(),
        'mediaUrls': mediaUrls,
        'objective': objective,
        'channels': channels,
        'audience': <String, dynamic>{
          'locations': locations,
          'ageMin': ageMin,
          'ageMax': ageMax,
          'interests': interests,
          'broad': broadAudience,
        },
        'budget': <String, dynamic>{
          'type': budgetType,
          'amount': budgetAmount,
          'currency': 'BRL',
        },
        'startAt': startAt?.toUtc().toIso8601String(),
        'endAt': endAt?.toUtc().toIso8601String(),
        'creative': <String, dynamic>{
          'headline': headline.trim(),
          'primaryText': primaryText.trim(),
          'description': description.trim(),
          'callToAction': callToAction,
        },
        'destination': <String, dynamic>{
          'type': destinationType,
          'url': destinationUrl.trim(),
          'captureFields': captureFields,
          'consentText': consentText.trim(),
        },
        'automation': <String, dynamic>{
          'initialMessage': initialMessage.trim(),
          'qualificationQuestions': qualificationQuestions,
          'pipelineStageId': pipelineStageId,
          'tags': tags,
          'onlyRegisterLead': onlyRegisterLead,
        },
        if (expectedVersion != null) 'expectedVersion': expectedVersion,
      };
}
