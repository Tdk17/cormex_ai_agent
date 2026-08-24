import 'package:agente_vendas_saas/Src/Shared/models/membership_model.dart';
import 'package:agente_vendas_saas/Src/Shared/models/user_model.dart';
import 'package:agente_vendas_saas/Src/Shared/models/workspace_model.dart';

class AuthSession {
  const AuthSession({
    required this.sessionToken,
    required this.user,
    this.workspaces = const <WorkspaceModel>[],
    this.memberships = const <MembershipModel>[],
    this.selectedWorkspaceId,
  });

  final String sessionToken;
  final UserModel user;
  final List<WorkspaceModel> workspaces;
  final List<MembershipModel> memberships;
  final String? selectedWorkspaceId;

  bool get hasWorkspace => workspaces.isNotEmpty;

  WorkspaceModel? get selectedWorkspace {
    if (workspaces.isEmpty) return null;
    return workspaces.firstWhere(
      (WorkspaceModel item) => item.id == selectedWorkspaceId,
      orElse: () => workspaces.first,
    );
  }

  AuthSession copyWith({
    String? sessionToken,
    UserModel? user,
    List<WorkspaceModel>? workspaces,
    List<MembershipModel>? memberships,
    String? selectedWorkspaceId,
  }) {
    return AuthSession(
      sessionToken: sessionToken ?? this.sessionToken,
      user: user ?? this.user,
      workspaces: workspaces ?? this.workspaces,
      memberships: memberships ?? this.memberships,
      selectedWorkspaceId: selectedWorkspaceId ?? this.selectedWorkspaceId,
    );
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      sessionToken: json['sessionToken']?.toString() ?? '',
      user: UserModel.fromJson(
        Map<String, dynamic>.from(json['user'] as Map? ?? const <String, dynamic>{}),
      ),
      workspaces: (json['workspaces'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (Map item) => WorkspaceModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      memberships: (json['memberships'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (Map item) => MembershipModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
      selectedWorkspaceId: json['selectedWorkspaceId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'sessionToken': sessionToken,
        'user': user.toJson(),
        'workspaces': workspaces.map((WorkspaceModel item) => item.toJson()).toList(),
        'memberships': memberships
            .map((MembershipModel item) => item.toJson())
            .toList(),
        'selectedWorkspaceId': selectedWorkspaceId,
      };
}
