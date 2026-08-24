enum MembershipRole { owner, admin, seller }

class MembershipModel {
  const MembershipModel({
    required this.id,
    required this.userId,
    required this.workspaceId,
    required this.role,
  });

  final String id;
  final String userId;
  final String workspaceId;
  final MembershipRole role;

  factory MembershipModel.fromJson(Map<String, dynamic> json) {
    return MembershipModel(
      id: (json['id'] ?? json['objectId'] ?? '').toString(),
      userId: json['userId']?.toString() ?? '',
      workspaceId: json['workspaceId']?.toString() ?? '',
      role: MembershipRole.values.firstWhere(
        (MembershipRole item) => item.name == json['role'],
        orElse: () => MembershipRole.seller,
      ),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'userId': userId,
        'workspaceId': workspaceId,
        'role': role.name,
      };
}
