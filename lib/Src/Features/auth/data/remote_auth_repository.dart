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
    } on Object {
      await _sessionStorage.clear();
      return null;
    }
  }

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    await _sessionStorage.clear();
    try {
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
      _validateAuthenticatedSession(session);
      await _sessionStorage.save(session);
      return await _loadCurrentUser(session);
    } on Object {
      await _sessionStorage.clear();
      rethrow;
    }
  }

  @override
  Future<AuthSession> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await _sessionStorage.clear();
    try {
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
      _validateAuthenticatedSession(session);
      await _sessionStorage.save(session);
      return session;
    } on Object {
      await _sessionStorage.clear();
      rethrow;
    }
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
    if (currentSession.hasWorkspace) return currentSession;

    final workspaceResult = await _httpManager.cloudFunction(
      name: Endpoints.workspacesCreate,
      parameters: <String, dynamic>{
        'name': workspaceName.trim(),
        'timezone': timezone,
        'companySegment': companySegment,
        'idempotencyKey': 'onboarding:${currentSession.user.id}',
        'initialAgent': <String, dynamic>{
          'name': agentName.trim(),
          'objective': agentObjective.trim(),
          'mode': 'assist',
        },
      },
    );
    final workspaceData = _unwrap(workspaceResult);
    final workspaceJson = workspaceData['workspace'] is Map
        ? Map<String, dynamic>.from(workspaceData['workspace'] as Map)
        : workspaceData;
    final workspace = WorkspaceModel.fromJson(<String, dynamic>{
      ...workspaceJson,
      'companySegment': workspaceJson['companySegment'] ?? companySegment,
    });
    if (workspace.id.isEmpty) {
      throw const ApiException(
        code: 'INTERNAL_ERROR',
        message: 'O servidor não retornou a empresa criada.',
      );
    }
    if (workspaceData['membership'] is! Map) {
      throw const ApiException(
        code: 'INTERNAL_ERROR',
        message: 'O servidor não confirmou o vínculo com a empresa.',
      );
    }
    final membership = MembershipModel.fromJson(
      Map<String, dynamic>.from(workspaceData['membership'] as Map),
    );
    if (membership.id.isEmpty ||
        membership.userId != currentSession.user.id ||
        membership.workspaceId != workspace.id ||
        membership.role != MembershipRole.owner) {
      throw const ApiException(
        code: 'INTERNAL_ERROR',
        message: 'O servidor retornou um vínculo de empresa inválido.',
      );
    }

    final refreshed = await _loadCurrentUser(currentSession);
    if (!refreshed.workspaces.any((item) => item.id == workspace.id)) {
      throw const ApiException(
        code: 'INTERNAL_ERROR',
        message: 'A empresa criada não foi confirmada na sessão.',
      );
    }
    return refreshed;
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
    if (data['user'] is! Map) {
      throw const ApiException(
        code: 'UNAUTHENTICATED',
        message: 'A sessão não foi confirmada pelo servidor.',
      );
    }
    final userData = Map<String, dynamic>.from(data['user'] as Map);
    final user = UserModel.fromJson(userData);
    if (user.id.isEmpty || user.id != baseSession.user.id) {
      throw const ApiException(
        code: 'UNAUTHENTICATED',
        message: 'A identidade da sessão não foi confirmada.',
      );
    }
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
    final authorizedMemberships = memberships
        .where((item) => item.userId == user.id)
        .toList(growable: false);
    final authorizedWorkspaceIds = authorizedMemberships
        .map((item) => item.workspaceId)
        .toSet();
    final authorizedWorkspaces = workspaces
        .where((item) => authorizedWorkspaceIds.contains(item.id))
        .toList(growable: false);
    final previousWorkspaceId = baseSession.selectedWorkspaceId;
    final selectedWorkspaceId = previousWorkspaceId != null &&
            authorizedWorkspaceIds.contains(previousWorkspaceId)
        ? previousWorkspaceId
        : authorizedWorkspaces.isEmpty
            ? null
            : authorizedWorkspaces.first.id;
    final session = AuthSession(
      sessionToken: baseSession.sessionToken,
      user: user,
      workspaces: authorizedWorkspaces,
      memberships: authorizedMemberships,
      selectedWorkspaceId: selectedWorkspaceId,
    );
    _validateAuthenticatedSession(session);
    await _sessionStorage.save(session);
    return session;
  }

  static void _validateAuthenticatedSession(AuthSession session) {
    if (session.sessionToken.isEmpty || session.user.id.isEmpty) {
      throw const ApiException(
        code: 'UNAUTHENTICATED',
        message: 'O servidor não retornou uma sessão válida.',
      );
    }
  }

  Map<String, dynamic> _unwrap(ApiResult<Map<String, dynamic>> result) {
    return switch (result) {
      ApiSuccess<Map<String, dynamic>>(:final data) => data,
      ApiFailure<Map<String, dynamic>>(:final error) => throw error,
    };
  }
}
