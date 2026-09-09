import 'package:agente_vendas_saas/Src/Core/api/api_exception.dart';
import 'package:agente_vendas_saas/Src/Core/utils/screen_state.dart';
import 'package:agente_vendas_saas/Src/Features/auth/presentation/controllers/auth_controller.dart';
import 'package:agente_vendas_saas/Src/Features/billing/domain/billing_models.dart';
import 'package:agente_vendas_saas/Src/Features/billing/domain/billing_repository.dart';
import 'package:signals/signals.dart';

class BillingController {
  BillingController(this._repository, this._authController);

  final BillingRepository _repository;
  final AuthController _authController;

  final Signal<ScreenState> state = signal(ScreenState.initial);
  final Signal<BillingOverviewModel?> overview = signal<BillingOverviewModel?>(null);
  final Signal<BillingCatalogModel?> catalog = signal<BillingCatalogModel?>(null);
  final Signal<BillingCycle> billingCycle = signal(BillingCycle.monthly);
  final Signal<bool> checkoutLoading = signal(false);
  final Signal<BillingCheckoutModel?> checkout = signal<BillingCheckoutModel?>(null);
  final Signal<String?> errorMessage = signal<String?>(null);
  final Signal<String?> correlationId = signal<String?>(null);

  String? get workspaceId => _authController.session.value?.selectedWorkspace?.id;

  Future<void> load({bool force = false}) async {
    if (!force && state.value == ScreenState.loading) return;
    final selectedWorkspaceId = workspaceId;
    if (selectedWorkspaceId == null) {
      state.value = ScreenState.empty;
      return;
    }

    batch(() {
      state.value = ScreenState.loading;
      errorMessage.value = null;
      correlationId.value = null;
    });

    try {
      final results = await Future.wait<Object>(<Future<Object>>[
        _repository.getCurrent(workspaceId: selectedWorkspaceId),
        _repository.listPlans(workspaceId: selectedWorkspaceId),
      ]);
      final current = results[0] as BillingOverviewModel;
      final plans = results[1] as BillingCatalogModel;
      batch(() {
        overview.value = current;
        catalog.value = plans;
        state.value = plans.plans.isEmpty ? ScreenState.empty : ScreenState.success;
      });
    } on ApiException catch (error) {
      batch(() {
        errorMessage.value = error.userMessage;
        correlationId.value = error.correlationId;
        state.value = ScreenState.error;
      });
    } on Object {
      batch(() {
        errorMessage.value = 'Não foi possível carregar os planos e a assinatura.';
        state.value = ScreenState.error;
      });
    }
  }

  void selectCycle(BillingCycle cycle) {
    billingCycle.value = cycle;
  }

  void clearCheckout() {
    checkout.value = null;
  }

  Future<BillingCheckoutModel?> createCheckout({
    required BillingCatalogPlanModel plan,
    required BillingPaymentMethod paymentMethod,
  }) async {
    final selectedWorkspaceId = workspaceId;
    if (selectedWorkspaceId == null || checkoutLoading.value) return null;

    batch(() {
      checkoutLoading.value = true;
      errorMessage.value = null;
      correlationId.value = null;
      checkout.value = null;
    });

    try {
      final result = await _repository.createCheckout(
        workspaceId: selectedWorkspaceId,
        planId: plan.id,
        billingCycle: billingCycle.value,
        paymentMethod: paymentMethod,
      );
      checkout.value = result;
      return result;
    } on ApiException catch (error) {
      batch(() {
        errorMessage.value = error.userMessage;
        correlationId.value = error.correlationId;
      });
      return null;
    } on Object {
      errorMessage.value = 'Não foi possível iniciar o pagamento.';
      return null;
    } finally {
      checkoutLoading.value = false;
    }
  }

  Future<BillingCheckoutModel?> refreshCheckout() async {
    final currentCheckout = checkout.value;
    final selectedWorkspaceId = workspaceId;
    if (currentCheckout == null || selectedWorkspaceId == null) return null;

    checkoutLoading.value = true;
    try {
      final updated = await _repository.getCheckoutStatus(
        workspaceId: selectedWorkspaceId,
        checkoutId: currentCheckout.id,
      );
      checkout.value = updated;
      if (updated.status == 'paid' || updated.status == 'active') {
        await load(force: true);
      }
      return updated;
    } on ApiException catch (error) {
      batch(() {
        errorMessage.value = error.userMessage;
        correlationId.value = error.correlationId;
      });
      return null;
    } on Object {
      errorMessage.value = 'Não foi possível atualizar o status do pagamento.';
      return null;
    } finally {
      checkoutLoading.value = false;
    }
  }
}
