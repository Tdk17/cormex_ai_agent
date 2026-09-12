enum MembershipRole {
  owner,
  admin,
  manager,
  salesManager,
  seller,
  salesRep,
  member,
  viewer,
}

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
      role: _roleFromApi(json['role']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'userId': userId,
        'workspaceId': workspaceId,
        'role': _roleToApi(role),
      };

  static MembershipRole _roleFromApi(dynamic raw) {
    final role = raw?.toString().trim().toLowerCase() ?? '';
    return switch (role) {
      'owner' => MembershipRole.owner,
      'admin' || 'administrator' || 'administrador' => MembershipRole.admin,
      'manager' || 'gestor' => MembershipRole.manager,
      'sales_manager' => MembershipRole.salesManager,
      'seller' || 'sales' || 'salesperson' || 'vendedor' => MembershipRole.seller,
      'sales_rep' => MembershipRole.salesRep,
      'member' => MembershipRole.member,
      'viewer' => MembershipRole.viewer,
      _ => MembershipRole.member,
    };
  }

  static String _roleToApi(MembershipRole role) => switch (role) {
        MembershipRole.owner => 'owner',
        MembershipRole.admin => 'admin',
        MembershipRole.manager => 'manager',
        MembershipRole.salesManager => 'sales_manager',
        MembershipRole.seller => 'seller',
        MembershipRole.salesRep => 'sales_rep',
        MembershipRole.member => 'member',
        MembershipRole.viewer => 'viewer',
      };
}
