import 'package:agente_vendas_saas/Src/Core/auth/auth_session.dart';

abstract interface class AuthRepository {
  Future<AuthSession?> restoreSession();

  Future<AuthSession> signIn({
    required String email,
    required String password,
  });

  Future<AuthSession> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<void> requestPasswordReset(String email);

  Future<AuthSession> completeOnboarding({
    required AuthSession currentSession,
    required String workspaceName,
    required String timezone,
    required String companySegment,
    required String agentName,
    required String agentObjective,
  });

  Future<void> saveSession(AuthSession session);
  Future<void> signOut();
}
