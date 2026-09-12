import 'dart:async';

import 'package:agente_vendas_saas/Src/Core/api/api_exception.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:agente_vendas_saas/Src/Features/billing/domain/billing_models.dart';
import 'package:agente_vendas_saas/Src/Features/billing/domain/billing_repository.dart';
import 'package:signals/signals.dart';

class BillingController {
  BillingController(this._repository, this._authController) {
    _disposeWorkspaceEffect = effect(() {
      final workspaceId = _workspaceId;
      if (_observedWorkspaceId == workspaceId) return;
      _observedWorkspaceId = workspaceId;
      batch(() {
        overview.value = null;
        catalog.value = null;
        errorMessage.value = null;
        correlationId.value = null;
        state.value = ScreenState.initial;
      });
      if (workspaceId != null) unawaited(load(force: true));
    });
  }

  final BillingRepository _repository;
  final AuthController _authController;
  String? _observedWorkspaceId;
  late final void Function() _disposeWorkspaceEffect;

  final Signal<ScreenState> state = signal(ScreenState.initial);
  final Signal<BillingOverviewModel?> overview = signal<BillingOverviewModel?>(null);
  final Signal<BillingCatalogModel?> catalog = signal<BillingCatalogModel?>(null);
  final Signal<String?> busyPlanCode = signal<String?>(null);
  final Signal<bool> isCancelling = signal(false);
  final Signal<String?> errorMessage = signal<String?>(null);
  final Signal<String?> correlationId = signal<String?>(null);

  Future<void> load({bool force = false}) async {
    if (!force && state.value == ScreenState.loading) return;
    final workspaceId = _workspaceId;
    if (workspaceId == null) {
      state.value = ScreenState.empty;
      return;
    }

    batch(() {
      state.value = ScreenState.loading;
      errorMessage.value = null;
      correlationId.value = null;
    });

    try {
      final current = await _repository.getCurrent(workspaceId: workspaceId);
      if (_workspaceId != workspaceId) return;
      batch(() {
        overview.value = current;
        state.value = ScreenState.success;
      });

      try {
        final plans = await _repository.getPlans(workspaceId: workspaceId);
        if (_workspaceId == workspaceId) catalog.value = plans;
      } on ApiException catch (error) {
        if (_workspaceId != workspaceId) return;
        // A assinatura atual continua utilizável mesmo se o catálogo ainda não
        // tiver sido configurado no servidor. O erro fica visível na própria tela.
        errorMessage.value = error.userMessage;
        correlationId.value = error.correlationId;
      } on Object {
        if (_workspaceId == workspaceId) {
          errorMessage.value = 'O catálogo de planos ainda não está disponível.';
        }
      }
    } on ApiException catch (error) {
      if (_workspaceId != workspaceId) return;
      batch(() {
        errorMessage.value = error.userMessage;
        correlationId.value = error.correlationId;
        state.value = ScreenState.error;
      });
    } on Object {
      if (_workspaceId != workspaceId) return;
      batch(() {
        errorMessage.value = 'Não foi possível carregar o estado da assinatura.';
        state.value = ScreenState.error;
      });
    }
  }

  Future<String?> startCheckout(BillingPlanModel plan, String returnUrl) async {
    final workspaceId = _workspaceId;
    if (workspaceId == null || busyPlanCode.value != null) return null;
    batch(() {
      busyPlanCode.value = plan.id;
      errorMessage.value = null;
    });
    try {
      final checkout = await _repository.checkout(
        workspaceId: workspaceId,
        planCode: plan.id,
        returnUrl: returnUrl,
      );
      return checkout.checkoutUrl.trim().isEmpty ? null : checkout.checkoutUrl.trim();
    } on ApiException catch (error) {
      errorMessage.value = error.userMessage;
      correlationId.value = error.correlationId;
      return null;
    } on Object {
      errorMessage.value = 'Não foi possível iniciar a assinatura.';
      return null;
    } finally {
      busyPlanCode.value = null;
    }
  }

  Future<bool> cancelSubscription() async {
    final workspaceId = _workspaceId;
    if (workspaceId == null || isCancelling.value) return false;
    batch(() {
      isCancelling.value = true;
      errorMessage.value = null;
    });
    try {
      overview.value = await _repository.cancel(workspaceId: workspaceId);
      return true;
    } on ApiException catch (error) {
      errorMessage.value = error.userMessage;
      correlationId.value = error.correlationId;
      return false;
    } on Object {
      errorMessage.value = 'Não foi possível cancelar a assinatura.';
      return false;
    } finally {
      isCancelling.value = false;
    }
  }

  String? get _workspaceId => _authController.session.value?.selectedWorkspace?.id;

  void dispose() => _disposeWorkspaceEffect();
}
