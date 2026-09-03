import 'package:agente_vendas_saas/Src/Core/api/api_result.dart';
import 'package:agente_vendas_saas/Src/Core/http/endpoints.dart';
import 'package:agente_vendas_saas/Src/Core/http/http_manager.dart';
import 'package:agente_vendas_saas/Src/Features/team/domain/team_models.dart';
import 'package:agente_vendas_saas/Src/Features/team/domain/team_repository.dart';

class RemoteTeamRepository implements TeamRepository {
  RemoteTeamRepository(this._httpManager);

  final HttpManager _httpManager;

  @override
  Future<TeamPageResult> list({required String workspaceId}) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.teamList,
      parameters: <String, dynamic>{'workspaceId': workspaceId},
    );
    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data, :final meta) => TeamPageResult(
          members: _maps(data['members'] ?? data['items'])
              .map(TeamMemberModel.fromJson)
              .toList(growable: false),
          invitations: _maps(data['invitations'] ?? data['invites'])
              .map(TeamInvitationModel.fromJson)
              .toList(growable: false),
          correlationId: meta.correlationId,
        ),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }

  @override
  Future<TeamInvitationModel> invite({
    required String workspaceId,
    required String email,
    required String role,
    required String clientRequestId,
  }) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.teamInvite,
      parameters: <String, dynamic>{
        'workspaceId': workspaceId,
        'email': email.trim().toLowerCase(),
        'role': role,
        'clientRequestId': clientRequestId,
      },
    );
    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data) =>
        TeamInvitationModel.fromJson(_map(data['invitation'] ?? data['invite'] ?? data)),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }

  @override
  Future<TeamMemberModel> updateRole({
    required String workspaceId,
    required String membershipId,
    required String role,
    required int expectedVersion,
  }) async {
    final result = await _httpManager.cloudFunction(
      name: Endpoints.teamUpdateRole,
      parameters: <String, dynamic>{
        'workspaceId': workspaceId,
        'membershipId': membershipId,
        'role': role,
        'expectedVersion': expectedVersion,
      },
    );
    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data) =>
        TeamMemberModel.fromJson(_map(data['member'] ?? data['membership'] ?? data)),
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }

  static Map<String, dynamic> _map(dynamic raw) => raw is Map
      ? Map<String, dynamic>.from(raw)
      : const <String, dynamic>{};

  static Iterable<Map<String, dynamic>> _maps(dynamic raw) {
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw.whereType<Map>().map(Map<String, dynamic>.from);
  }
}
