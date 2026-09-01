import 'dart:async';

import 'package:agente_vendas_saas/Src/Core/api/api_exception.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/acquisition/domain/acquisition_contracts.dart';
import 'package:agente_vendas_saas/Src/Features/acquisition/domain/acquisition_repository.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:agente_vendas_saas/Src/Shared/models/acquisition_models.dart';
import 'package:signals/signals.dart';

class AcquisitionController {
  AcquisitionController(this._repository, this._authController) {
    _disposeWorkspaceEffect = effect(() {
      final workspaceId = _workspaceId;
      if (_observedWorkspaceId == workspaceId) return;
      _observedWorkspaceId = workspaceId;
      batch(() {
        metrics.value = null;
        accounts.value = const <AcquisitionAdAccountModel>[];
        campaigns.value = const <AcquisitionCampaignModel>[];
        nextCursor.value = null;
        errorMessage.value = null;
        correlationId.value = null;
        state.value = ScreenState.initial;
      });
      if (workspaceId != null) unawaited(load(force: true));
    });
  }

  final AcquisitionRepository _repository;
  final AuthController _authController;
  String? _observedWorkspaceId;
  late final void Function() _disposeWorkspaceEffect;

  final Signal<ScreenState> state = signal(ScreenState.initial);
  final Signal<AcquisitionMetricsModel?> metrics =
      signal<AcquisitionMetricsModel?>(null);
  final Signal<List<AcquisitionAdAccountModel>> accounts =
      signal<List<AcquisitionAdAccountModel>>(
    const <AcquisitionAdAccountModel>[],
  );
  final Signal<List<AcquisitionCampaignModel>> campaigns =
      signal<List<AcquisitionCampaignModel>>(
    const <AcquisitionCampaignModel>[],
  );
  final Signal<String> period = signal('30d');
  final Signal<String?> channel = signal<String?>(null);
  final Signal<String?> status = signal<String?>(null);
  final Signal<String?> nextCursor = signal<String?>(null);
  final Signal<bool> isLoadingMore = signal(false);
  final Signal<Set<String>> mutatingIds = signal<Set<String>>(<String>{});
  final Signal<String?> errorMessage = signal<String?>(null);
  final Signal<String?> correlationId = signal<String?>(null);
  final Signal<String?> actionMessage = signal<String?>(null);

  bool get hasConnectedAccount =>
      accounts.value.any((AcquisitionAdAccountModel item) => item.isConnected);

  Future<void> load({bool force = false, bool append = false}) async {
    if (append) {
      if (isLoadingMore.value || nextCursor.value == null) return;
      isLoadingMore.value = true;
    } else {
      if (!force && state.value == ScreenState.loading) return;
      batch(() {
        state.value = ScreenState.loading;
        errorMessage.value = null;
        correlationId.value = null;
        actionMessage.value = null;
      });
    }

    final workspaceId = _workspaceId;
    if (workspaceId == null) {
      batch(() {
        state.value = ScreenState.empty;
        isLoadingMore.value = false;
      });
      return;
    }

    try {
      final result = await _repository.overview(
        workspaceId: workspaceId,
        period: period.value,
        channel: channel.value,
        status: status.value,
        cursor: append ? nextCursor.value : null,
      );
      if (_workspaceId != workspaceId) return;
      batch(() {
        metrics.value = result.metrics;
        accounts.value = result.accounts;
        campaigns.value = append
            ? <AcquisitionCampaignModel>[
                ...campaigns.value,
                ...result.campaigns,
              ]
            : result.campaigns;
        nextCursor.value = result.nextCursor;
        correlationId.value = result.correlationId;
        state.value = ScreenState.success;
      });
    } on ApiException catch (error) {
      if (_workspaceId != workspaceId) return;
      batch(() {
        errorMessage.value = error.userMessage;
        correlationId.value = error.correlationId;
        state.value = campaigns.value.isEmpty
            ? ScreenState.error
            : ScreenState.success;
      });
    } on Object {
      if (_workspaceId != workspaceId) return;
      batch(() {
        errorMessage.value = 'Não foi possível carregar a Central de Aquisição.';
        state.value = campaigns.value.isEmpty
            ? ScreenState.error
            : ScreenState.success;
      });
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<bool> performAction(
    AcquisitionCampaignModel campaign,
    String action,
  ) async {
    if (mutatingIds.value.contains(campaign.id)) return false;
    final workspaceId = _workspaceId;
    if (workspaceId == null) return false;
    batch(() {
      mutatingIds.value = <String>{...mutatingIds.value, campaign.id};
      errorMessage.value = null;
      actionMessage.value = null;
    });
    try {
      final result = await _repository.campaignAction(
        workspaceId: workspaceId,
        campaignId: campaign.id,
        action: action,
        expectedVersion: campaign.version,
        clientRequestId: _requestId(action, campaign.id),
      );
      if (_workspaceId != workspaceId) return false;
      _replace(
        result.campaign,
        insertWhenMissing: action == AcquisitionCampaignAction.duplicate,
      );
      batch(() {
        correlationId.value = result.correlationId;
        actionMessage.value = _actionSuccess(action);
      });
      return true;
    } on ApiException catch (error) {
      if (_workspaceId == workspaceId) {
        batch(() {
          errorMessage.value = error.code == 'CONFLICT'
              ? 'A campanha mudou em outra sessão. Atualize antes de tentar novamente.'
              : error.userMessage;
          correlationId.value = error.correlationId;
        });
      }
      return false;
    } on Object {
      errorMessage.value = 'Não foi possível atualizar a campanha.';
      return false;
    } finally {
      mutatingIds.value = <String>{...mutatingIds.value}..remove(campaign.id);
    }
  }

  void changeFilters({String? periodValue, String? channelValue, String? statusValue}) {
    if (periodValue != null) period.value = periodValue;
    channel.value = channelValue;
    status.value = statusValue;
    unawaited(load(force: true));
  }

  void upsert(AcquisitionCampaignModel campaign) {
    _replace(campaign, insertWhenMissing: true);
    state.value = ScreenState.success;
  }

  void clearFeedback() {
    batch(() {
      errorMessage.value = null;
      actionMessage.value = null;
    });
  }

  void _replace(
    AcquisitionCampaignModel campaign, {
    bool insertWhenMissing = false,
  }) {
    final next = <AcquisitionCampaignModel>[...campaigns.value];
    final index = next.indexWhere(
      (AcquisitionCampaignModel item) => item.id == campaign.id,
    );
    if (index >= 0) {
      next[index] = campaign;
    } else if (insertWhenMissing) {
      next.insert(0, campaign);
    }
    campaigns.value = next;
  }

  String? get _workspaceId =>
      _authController.session.value?.selectedWorkspace?.id;

  static String _requestId(String operation, String campaignId) =>
      '$operation:$campaignId:${DateTime.now().microsecondsSinceEpoch}';

  static String _actionSuccess(String action) => switch (action) {
        AcquisitionCampaignAction.pause => 'Campanha pausada.',
        AcquisitionCampaignAction.resume => 'Campanha retomada.',
        AcquisitionCampaignAction.duplicate => 'Cópia criada como rascunho.',
        AcquisitionCampaignAction.finish => 'Campanha encerrada.',
        _ => 'Campanha atualizada.',
      };

  void dispose() => _disposeWorkspaceEffect();
}
