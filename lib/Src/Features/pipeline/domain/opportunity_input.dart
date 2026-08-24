class OpportunityInput {
  const OpportunityInput({
    required this.leadId,
    required this.stageId,
    required this.title,
    required this.companyName,
    required this.contactName,
    required this.value,
    required this.probability,
    required this.source,
    this.ownerId,
    this.ownerName,
    this.product,
    this.nextActivityAt,
    this.outcome = 'open',
  });

  final String leadId;
  final String stageId;
  final String title;
  final String companyName;
  final String contactName;
  final double value;
  final int probability;
  final String? ownerId;
  final String? ownerName;
  final String? product;
  final String source;
  final String outcome;
  final DateTime? nextActivityAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'leadId': leadId,
      'stageId': stageId,
      'title': title.trim(),
      'companyName': companyName.trim(),
      'contactName': contactName.trim(),
      'value': value,
      'probability': probability,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'product': (product?.trim().isEmpty ?? true) ? null : product!.trim(),
      'source': source,
      'outcome': outcome,
      'nextActivityAt': nextActivityAt?.toUtc().toIso8601String(),
    };
  }
}
