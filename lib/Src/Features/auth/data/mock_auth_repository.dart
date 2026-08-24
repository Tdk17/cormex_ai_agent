import 'package:agente_vendas_saas/Src/Core/auth/auth_session.dart';
import 'package:agente_vendas_saas/Src/Core/auth/session_storage.dart';
import 'package:agente_vendas_saas/Src/Features/auth/domain/auth_repository.dart';
import 'package:agente_vendas_saas/Src/Shared/models/membership_model.dart';
import 'package:agente_vendas_saas/Src/Shared/models/user_model.dart';
import 'package:agente_vendas_saas/Src/Shared/models/workspace_model.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._sessionStorage);

  final SessionStorage _sessionStorage;

  @override
  Future<AuthSession?> restoreSession() => _sessionStorage.read();

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    final cached = await _sessionStorage.read();
    if (cached != null && cached.user.email == email.trim().toLowerCase()) {
      return cached;
    }
    final session = _newSession(name: 'Pedro Henrique', email: email);
    await _sessionStorage.save(session);
    return session;
  }

  @override
  Future<AuthSession> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final session = _newSession(name: name, email: email);
    await _sessionStorage.save(session);
    return session;
  }

  @override
  Future<void> requestPasswordReset(String email) {
    return Future<void>.delayed(const Duration(milliseconds: 650));
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
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final suffix = DateTime.now().millisecondsSinceEpoch.toString();
    final workspace = WorkspaceModel(
      id: 'ws_$suffix',
      name: workspaceName.trim(),
      timezone: timezone,
      companySegment: companySegment,
    );
    final membership = MembershipModel(
      id: 'membership_$suffix',
      userId: currentSession.user.id,
      workspaceId: workspace.id,
      role: MembershipRole.owner,
    );
    final session = currentSession.copyWith(
      workspaces: <WorkspaceModel>[...currentSession.workspaces, workspace],
      memberships: <MembershipModel>[...currentSession.memberships, membership],
      selectedWorkspaceId: workspace.id,
    );
    await _sessionStorage.save(session);
    return session;
  }

  @override
  Future<void> saveSession(AuthSession session) => _sessionStorage.save(session);

  @override
  Future<void> signOut() => _sessionStorage.clear();

  AuthSession _newSession({required String name, required String email}) {
    final normalizedEmail = email.trim().toLowerCase();
    return AuthSession(
      sessionToken: 'mock_session_${DateTime.now().millisecondsSinceEpoch}',
      user: UserModel(
        id: 'user_mock',
        name: name.trim(),
        email: normalizedEmail,
      ),
    );
  }
}
