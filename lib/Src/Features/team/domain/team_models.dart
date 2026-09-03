class TeamMemberModel {
  const TeamMemberModel({
    required this.membershipId,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.status = 'active',
    this.avatarUrl,
    this.lastActiveAt,
    this.version = 0,
  });

  final String membershipId;
  final String userId;
  final String name;
  final String email;
  final String role;
  final String status;
  final String? avatarUrl;
  final DateTime? lastActiveAt;
  final int version;

  factory TeamMemberModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'] as Map)
        : const <String, dynamic>{};
    return TeamMemberModel(
      membershipId:
          (json['membershipId'] ?? json['id'] ?? json['objectId'] ?? '').toString(),
      userId: (user['id'] ?? user['objectId'] ?? json['userId'] ?? '').toString(),
      name: (user['name'] ?? json['name'] ?? user['username'] ?? '').toString(),
      email: (user['email'] ?? json['email'] ?? '').toString(),
      role: (json['role'] ?? 'seller').toString(),
      status: (json['status'] ?? 'active').toString(),
      avatarUrl: (user['avatarUrl'] ?? json['avatarUrl'])?.toString(),
      lastActiveAt: _date(json['lastActiveAt']),
      version: (json['version'] as num?)?.toInt() ?? 0,
    );
  }

  static DateTime? _date(dynamic value) {
    if (value is Map && value['iso'] != null) {
      return DateTime.tryParse(value['iso'].toString());
    }
    return DateTime.tryParse(value?.toString() ?? '');
  }
}

class TeamInvitationModel {
  const TeamInvitationModel({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    this.expiresAt,
  });

  final String id;
  final String email;
  final String role;
  final String status;
  final DateTime? expiresAt;

  factory TeamInvitationModel.fromJson(Map<String, dynamic> json) {
    return TeamInvitationModel(
      id: (json['id'] ?? json['objectId'] ?? '').toString(),
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'seller',
      status: json['status']?.toString() ?? 'pending',
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? ''),
    );
  }
}

class TeamPageResult {
  const TeamPageResult({
    required this.members,
    required this.invitations,
    this.correlationId,
  });

  final List<TeamMemberModel> members;
  final List<TeamInvitationModel> invitations;
  final String? correlationId;
}
