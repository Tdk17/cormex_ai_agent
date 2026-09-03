import 'package:agente_vendas_saas/Src/Features/team/domain/team_models.dart';

abstract interface class TeamRepository {
  Future<TeamPageResult> list({required String workspaceId});

  Future<TeamInvitationModel> invite({
    required String workspaceId,
    required String email,
    required String role,
    required String clientRequestId,
  });

  Future<TeamMemberModel> updateRole({
    required String workspaceId,
    required String membershipId,
    required String role,
    required int expectedVersion,
  });
}
