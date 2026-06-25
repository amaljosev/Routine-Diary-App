// lib/features/premium/presentation/bloc/premium_state.dart

part of 'premium_bloc.dart';

enum PremiumLoadingState { initial, loading, purchasing, idle }

class PremiumState {
  final PremiumStatus status;
  final PremiumLoadingState loadingState;
  final List<ProductDetails> subscriptionPlans;
  final String? errorMessage;

  /// Becomes [true] exactly once when the store confirms the cached subscription
  /// has lapsed. [main.dart]'s BlocListener watches this flag to reset the
  /// custom theme — it only acts on the false → true transition.
  final bool subscriptionExpired;

  /// Becomes [true] when the subscription expires so DiaryScreen can show a
  /// one-time "Your subscription has expired" banner. Reset to [false] by
  /// dispatching [PremiumExpiredBannerShown] after the banner is displayed.
  final bool showExpiredBanner;

  const PremiumState({
    this.status = const PremiumStatus.free(),
    this.loadingState = PremiumLoadingState.initial,
    this.subscriptionPlans = const [],
    this.errorMessage,
    this.subscriptionExpired = false,
    this.showExpiredBanner = false,
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
    bool clearError = false,
    bool? subscriptionExpired,
    bool? showExpiredBanner,
  }) =>
      PremiumState(
        status: status ?? this.status,
        loadingState: loadingState ?? this.loadingState,
        subscriptionPlans:
            clearPlans ? [] : (subscriptionPlans ?? this.subscriptionPlans),
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        subscriptionExpired:
            subscriptionExpired ?? this.subscriptionExpired,
        showExpiredBanner: showExpiredBanner ?? this.showExpiredBanner,
      );
}