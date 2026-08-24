import 'package:agente_vendas_saas/Src/Core/api/api_exception.dart';
import 'package:agente_vendas_saas/Src/Core/auth/auth_session.dart';
import 'package:agente_vendas_saas/Src/Features/auth/domain/auth_repository.dart';
import 'package:signals/signals.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthController {
  AuthController(this._repository);

  final AuthRepository _repository;

  final Signal<AuthStatus> status = signal(AuthStatus.initial);
  final Signal<AuthSession?> session = signal<AuthSession?>(null);
  final Signal<String?> errorMessage = signal<String?>(null);
  final Signal<String?> correlationId = signal<String?>(null);
  final Signal<bool> isMutating = signal(false);

  late final isLoading = computed(
    () => status.value == AuthStatus.loading || isMutating.value,
  );
  late final isAuthenticated = computed(() => session.value != null);
  late final hasWorkspace = computed(() => session.value?.hasWorkspace ?? false);

  Future<void> initialize() async {
    if (status.value != AuthStatus.initial) return;
    status.value = AuthStatus.loading;
    try {
      final restored = await _repository.restoreSession();
      batch(() {
        session.value = restored;
        status.value = restored == null
            ? AuthStatus.unauthenticated
            : AuthStatus.authenticated;
      });
    } on Object {
      batch(() {
        session.value = null;
        status.value = AuthStatus.unauthenticated;
      });
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    if (isLoading.value) return false;
    return _execute(
      () => _repository.signIn(email: email, password: password),
    );
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    if (isLoading.value) return false;
    return _execute(
      () => _repository.signUp(name: name, email: email, password: password),
    );
  }

  Future<bool> completeOnboarding({
    required String workspaceName,
    required String timezone,
    required String companySegment,
    required String agentName,
    required String agentObjective,
  }) async {
    final current = session.value;
    if (current == null || isLoading.value) return false;
    return _execute(
      () => _repository.completeOnboarding(
        currentSession: current,
        workspaceName: workspaceName,
        timezone: timezone,
        companySegment: companySegment,
        agentName: agentName,
        agentObjective: agentObjective,
      ),
    );
  }

  Future<void> selectWorkspace(String workspaceId) async {
    final current = session.value;
    if (current == null ||
        !current.workspaces.any((workspace) => workspace.id == workspaceId)) {
      return;
    }
    final next = current.copyWith(selectedWorkspaceId: workspaceId);
    session.value = next;
    await _repository.saveSession(next);
  }

  Future<void> signOut() async {
    if (isLoading.value) return;
    isMutating.value = true;
    try {
      await _repository.signOut();
    } finally {
      batch(() {
        session.value = null;
        errorMessage.value = null;
        correlationId.value = null;
        isMutating.value = false;
        status.value = AuthStatus.unauthenticated;
      });
    }
  }

  Future<bool> _execute(Future<AuthSession> Function() action) async {
    batch(() {
      isMutating.value = true;
      errorMessage.value = null;
      correlationId.value = null;
    });
    try {
      final result = await action();
      batch(() {
        session.value = result;
        isMutating.value = false;
        status.value = AuthStatus.authenticated;
      });
      return true;
    } on ApiException catch (error) {
      batch(() {
        errorMessage.value = error.userMessage;
        correlationId.value = error.correlationId;
        isMutating.value = false;
        status.value = session.value == null
            ? AuthStatus.unauthenticated
            : AuthStatus.authenticated;
      });
      return false;
    } on Object {
      batch(() {
        errorMessage.value = 'Não foi possível concluir a operação.';
        isMutating.value = false;
        status.value = session.value == null
            ? AuthStatus.unauthenticated
            : AuthStatus.authenticated;
      });
      return false;
    }
  }
}
