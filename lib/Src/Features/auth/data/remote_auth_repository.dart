import 'package:agente_vendas_saas/Src/Core/api/api_exception.dart';
import 'package:agente_vendas_saas/Src/Core/api/api_result.dart';
import 'package:agente_vendas_saas/Src/Core/auth/auth_session.dart';
import 'package:agente_vendas_saas/Src/Core/auth/session_storage.dart';
import 'package:agente_vendas_saas/Src/Core/http/endpoints.dart';
import 'package:agente_vendas_saas/Src/Core/http/http_manager.dart';
import 'package:agente_vendas_saas/Src/Core/http/http_method.dart';
import 'package:agente_vendas_saas/Src/Features/auth/domain/auth_repository.dart';
import 'package:agente_vendas_saas/Src/Shared/models/membership_model.dart';
import 'package:agente_vendas_saas/Src/Shared/models/user_model.dart';
import 'package:agente_vendas_saas/Src/Shared/models/workspace_model.dart';

class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository({
    required HttpManager httpManager,
    required SessionStorage sessionStorage,
  })  : _httpManager = httpManager,
        _sessionStorage = sessionStorage;

  final HttpManager _httpManager;
  final SessionStorage _sessionStorage;

  @override
  Future<AuthSession?> restoreSession() async {
    final cached = await _sessionStorage.read();
    if (cached == null || cached.sessionToken.isEmpty) return null;

    try {
      return await _loadCurrentUser(cached);
    } on ApiException catch (error) {
      if (error.code == 'UNAUTHENTICATED') {
        await _sessionStorage.clear();
        return null;
      }
      return cached;
    }
  }

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    final result = await _httpManager.restRequest(
      endpoint: Endpoints.login,
      method: HttpMethod.get,
      queryParameters: <String, dynamic>{
        'username': email.trim().toLowerCase(),
        'password': password,
      },
      requiresAuth: false,
    );
    final data = _unwrap(result);
    final session = AuthSession(
      sessionToken: data['sessionToken']?.toString() ?? '',
      user: UserModel.fromJson(data),
    );
    if (session.sessionToken.isEmpty) {
      throw const ApiException(
        code: 'UNAUTHENTICATED',
        message: 'O servidor não retornou uma sessão válida.',
      );
    }
    await _sessionStorage.save(session);
    return _loadCurrentUser(session);
  }

  @override
  Future<AuthSession> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final result = await _httpManager.restRequest(
      endpoint: Endpoints.users,
      method: HttpMethod.post,
      body: <String, dynamic>{
        'name': name.trim(),
        'username': normalizedEmail,
        'email': normalizedEmail,
        'password': password,
      },
      requiresAuth: false,
    );
    final data = _unwrap(result);
    final session = AuthSession(
      sessionToken: data['sessionToken']?.toString() ?? '',
      user: UserModel(
        id: (data['objectId'] ?? data['id'] ?? '').toString(),
        name: name.trim(),
        email: normalizedEmail,
      ),
    );
    await _sessionStorage.save(session);
    return session;
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    final result = await _httpManager.restRequest(
      endpoint: Endpoints.requestPasswordReset,
      method: HttpMethod.post,
      body: <String, dynamic>{'email': email.trim().toLowerCase()},
      requiresAuth: false,
    );
    _unwrap(result);
  }

  @override
  Future<AuthSession> completeOnboarding({
    required AuthSession currentSession,
    required String workspaceName,
    required String timezone,
    required String companySegment,
    required String agentName,
    required String agentObjective,
  }) async {
    final workspaceResult = await _httpManager.cloudFunction(
      name: Endpoints.workspacesCreate,
      parameters: <String, dynamic>{
        'name': workspaceName.trim(),
        'timezone': timezone,
      },
    );
    final workspaceData = _unwrap(workspaceResult);
    final workspaceJson = workspaceData['workspace'] is Map
        ? Map<String, dynamic>.from(workspaceData['workspace'] as Map)
        : workspaceData;
    final workspace = WorkspaceModel.fromJson(
      <String, dynamic>{
        ...workspaceJson,
        'companySegment': companySegment,
      },
    );
    final membership = workspaceData['membership'] is Map
        ? MembershipModel.fromJson(
            Map<String, dynamic>.from(workspaceData['membership'] as Map),
          )
        : MembershipModel(
            id: 'membership_${workspace.id}',
            userId: currentSession.user.id,
            workspaceId: workspace.id,
            role: MembershipRole.owner,
          );

    final nextSession = currentSession.copyWith(
      workspaces: <WorkspaceModel>[...currentSession.workspaces, workspace],
      memberships: <MembershipModel>[...currentSession.memberships, membership],
      selectedWorkspaceId: workspace.id,
    );

    final agentResult = await _httpManager.cloudFunction(
      name: Endpoints.agentUpdate,
      parameters: <String, dynamic>{
        'workspaceId': workspace.id,
        'name': agentName.trim(),
        'objective': agentObjective.trim(),
        'mode': 'assist',
      },
    );
    _unwrap(agentResult);
    await _sessionStorage.save(nextSession);
    return nextSession;
  }

  @override
  Future<void> saveSession(AuthSession session) => _sessionStorage.save(session);

  @override
  Future<void> signOut() async {
    try {
      await _httpManager.restRequest(
        endpoint: Endpoints.logout,
        method: HttpMethod.post,
      );
    } finally {
      await _sessionStorage.clear();
    }
  }

  Future<AuthSession> _loadCurrentUser(AuthSession baseSession) async {
    final result = await _httpManager.cloudFunction(name: Endpoints.authMe);
    final data = _unwrap(result);
    final userData = data['user'] is Map
        ? Map<String, dynamic>.from(data['user'] as Map)
        : baseSession.user.toJson();
    final workspaces = (data['workspaces'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map>()
        .map(
          (Map item) => WorkspaceModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
    final memberships =
        (data['memberships'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map>()
            .map(
              (Map item) => MembershipModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false);
    final session = AuthSession(
      sessionToken: baseSession.sessionToken,
      user: UserModel.fromJson(userData),
      workspaces: workspaces,
      memberships: memberships,
      selectedWorkspaceId: baseSession.selectedWorkspaceId ??
          (workspaces.isEmpty ? null : workspaces.first.id),
    );
    await _sessionStorage.save(session);
    return session;
  }

  Map<String, dynamic> _unwrap(ApiResult<Map<String, dynamic>> result) {
    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data) => data,
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }
}
