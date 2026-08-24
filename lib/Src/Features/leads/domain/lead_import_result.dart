class LeadImportResult {
  const LeadImportResult({
    required this.total,
    required this.accepted,
    required this.rejected,
    this.jobId,
  });

  final int total;
  final int accepted;
  final int rejected;
  final String? jobId;

  factory LeadImportResult.fromJson(Map<String, dynamic> json) {
    return LeadImportResult(
      total: (json['total'] as num?)?.toInt() ?? 0,
      accepted: (json['accepted'] as num?)?.toInt() ??
          (json['created'] as num?)?.toInt() ??
          0,
      rejected: (json['rejected'] as num?)?.toInt() ??
          (json['errors'] as List<dynamic>?)?.length ??
          0,
      jobId: json['jobId']?.toString(),
    );
  }
}
