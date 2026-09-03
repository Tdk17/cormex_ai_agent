import 'dart:async';

import 'package:agente_vendas_saas/Src/Core/api/api_exception.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:agente_vendas_saas/Src/Features/team/domain/team_models.dart';
import 'package:agente_vendas_saas/Src/Features/team/domain/team_repository.dart';
import 'package:agente_vendas_saas/Src/Shared/models/membership_model.dart';
import 'package:signals/signals.dart';

class TeamController {
  TeamController(this._repository, this._authController) {
    _disposeWorkspaceEffect = effect(() {
      final workspaceId = _workspaceId;
      if (_observedWorkspaceId == workspaceId) return;
      _observedWorkspaceId = workspaceId;
      batch(() {
        members.value = const <TeamMemberModel>[];
        invitations.value = const <TeamInvitationModel>[];
        state.value = ScreenState.initial;
      });
      if (workspaceId != null) unawaited(load(force: true));
    });
  }

  final TeamRepository _repository;
  final AuthController _authController;
  late final void Function() _disposeWorkspaceEffect;
  String? _observedWorkspaceId;

  final Signal<ScreenState> state = signal(ScreenState.initial);
  final Signal<List<TeamMemberModel>> members =
      signal<List<TeamMemberModel>>(const <TeamMemberModel>[]);
  final Signal<List<TeamInvitationModel>> invitations =
      signal<List<TeamInvitationModel>>(const <TeamInvitationModel>[]);
  final Signal<bool> isMutating = signal(false);
  final Signal<String?> errorMessage = signal<String?>(null);
  final Signal<String?> successMessage = signal<String?>(null);
  final Signal<String?> correlationId = signal<String?>(null);

  bool get canManage {
    final session = _authController.session.value;
    final workspaceId = _workspaceId;
    if (session == null || workspaceId == null) return false;
    final matches = session.memberships.where(
      (MembershipModel item) =>
          item.workspaceId == workspaceId && item.userId == session.user.id,
    );
    if (matches.isEmpty) return false;
    return matches.first.role == MembershipRole.owner ||
        matches.first.role == MembershipRole.admin;
  }

  Future<void> load({bool force = false}) async {
    if (!force && state.value == ScreenState.loading) return;
    final workspaceId = _workspaceId;
    if (workspaceId == null) return;
    batch(() {
      state.value = ScreenState.loading;
      errorMessage.value = null;
    });
    try {
      final page = await _repository.list(workspaceId: workspaceId);
      if (_workspaceId != workspaceId) return;
      batch(() {
        members.value = page.members;
        invitations.value = page.invitations;
        correlationId.value = page.correlationId;
        state.value = page.members.isEmpty ? ScreenState.empty : ScreenState.success;
      });
    } on ApiException catch (error) {
      _setError(error.userMessage, error.correlationId, pageError: true);
    } on Object {
      _setError('Não foi possível carregar a equipe.', null, pageError: true);
    }
  }

  Future<bool> invite(String email, String role) async {
    final workspaceId = _workspaceId;
    if (workspaceId == null || isMutating.value || !canManage) return false;
    if (!_emailPattern.hasMatch(email.trim())) {
      errorMessage.value = 'Informe um e-mail válido.';
      return false;
    }
    batch(() {
      isMutating.value = true;
      errorMessage.value = null;
      successMessage.value = null;
    });
    try {
      final invitation = await _repository.invite(
        workspaceId: workspaceId,
        email: email,
        role: role,
        clientRequestId: 'team_invite_${DateTime.now().microsecondsSinceEpoch}',
      );
      invitations.value = <TeamInvitationModel>[
        invitation,
        ...invitations.value.where(
          (TeamInvitationModel item) => item.id != invitation.id,
        ),
      ];
      successMessage.value = 'Convite enviado para ${invitation.email}.';
      return true;
    } on ApiException catch (error) {
      _setError(error.userMessage, error.correlationId);
      return false;
    } on Object {
      errorMessage.value = 'Não foi possível enviar o convite.';
      return false;
    } finally {
      isMutating.value = false;
    }
  }

  Future<bool> updateRole(TeamMemberModel member, String role) async {
    final workspaceId = _workspaceId;
    if (workspaceId == null || isMutating.value || !canManage) return false;
    if (member.role == 'owner') {
      errorMessage.value =
          'A transferência de proprietário exige um fluxo específico.';
      return false;
    }
    batch(() {
      isMutating.value = true;
      errorMessage.value = null;
      successMessage.value = null;
    });
    try {
      final updated = await _repository.updateRole(
        workspaceId: workspaceId,
        membershipId: member.membershipId,
        role: role,
        expectedVersion: member.version,
      );
      final items = <TeamMemberModel>[...members.value];
      final index = items.indexWhere(
        (TeamMemberModel item) => item.membershipId == updated.membershipId,
      );
      if (index >= 0) items[index] = updated;
      members.value = items;
      successMessage.value = 'Papel de ${updated.name} atualizado.';
      return true;
    } on ApiException catch (error) {
      _setError(
        error.code == 'CONFLICT'
            ? 'A equipe foi alterada em outra sessão. Atualize e tente novamente.'
            : error.userMessage,
        error.correlationId,
      );
      return false;
    } on Object {
      errorMessage.value = 'Não foi possível alterar o papel.';
      return false;
    } finally {
      isMutating.value = false;
    }
  }

  void clearFeedback() {
    errorMessage.value = null;
    successMessage.value = null;
  }

  String? get _workspaceId =>
      _authController.session.value?.selectedWorkspace?.id;

  static final RegExp _emailPattern =
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  void _setError(
    String message,
    String? requestCorrelationId, {
    bool pageError = false,
  }) {
    batch(() {
      errorMessage.value = message;
      correlationId.value = requestCorrelationId;
      if (pageError) state.value = ScreenState.error;
    });
  }

  void dispose() => _disposeWorkspaceEffect();
}
