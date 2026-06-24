part of 'premium_bloc.dart';



enum PremiumLoadingState { initial, loading, purchasing, idle }
 
class PremiumState {
  final PremiumStatus status;
  final PremiumLoadingState loadingState;
  final List<ProductDetails> subscriptionPlans; // all 3 plans
  final String? errorMessage;
 
  const PremiumState({
    this.status = const PremiumStatus.free(),
    this.loadingState = PremiumLoadingState.initial,
    this.subscriptionPlans = const [], // default to empty, not required
    this.errorMessage,
  });
 
  // ── Convenience getters used by UI ────────────────────────────────────────
 
  bool get isPremium => status.isPremium;
  bool get isPurchasing => loadingState == PremiumLoadingState.purchasing;
  bool get isLoading => loadingState == PremiumLoadingState.loading;
  bool get hasPlans => subscriptionPlans.isNotEmpty;
 
  PremiumState copyWith({
    PremiumStatus? status,
    PremiumLoadingState? loadingState,
    List<ProductDetails>? subscriptionPlans,
    bool clearPlans = false,
    String? errorMessage,
  }) =>
      PremiumState(
        status: status ?? this.status,
        loadingState: loadingState ?? this.loadingState,
        subscriptionPlans:
            clearPlans ? [] : (subscriptionPlans ?? this.subscriptionPlans),
        // Pass null explicitly to clear the error
        errorMessage: errorMessage,
      );
}