// lib/features/premium/presentation/bloc/premium_state.dart
part of 'premium_bloc.dart';

enum PremiumLoadingState { idle, loading, purchasing }

class PremiumState {
  final PremiumStatus status;
  final PremiumLoadingState loadingState;
  final List<ProductDetails> subscriptionPlans;
  final String? errorMessage;

  /// True during the session in which a subscription expired. Used by the
  /// BlocListener in main.dart to fire DeactivateCustomTheme once.
  final bool subscriptionExpired;

  /// True when the diary screen should surface the "subscription expired" banner.
  final bool showExpiredBanner;

  /// True if the user has ever held a subscription (never cleared on expiry).
  /// Drives the "Restore Custom Theme" button visibility.
  final bool wasEverSubscriber;

  const PremiumState({
    this.status = const PremiumStatus.free(),
    this.loadingState = PremiumLoadingState.idle,
    this.subscriptionPlans = const [],
    this.errorMessage,
    this.subscriptionExpired = false,
    this.showExpiredBanner = false,
    this.wasEverSubscriber = false,
  });

  bool get isPremium => status.isPremium;
  bool get isLoading => loadingState == PremiumLoadingState.loading;
  bool get isPurchasing => loadingState == PremiumLoadingState.purchasing;
  bool get hasPlans => subscriptionPlans.isNotEmpty;

  PremiumState copyWith({
    PremiumStatus? status,
    PremiumLoadingState? loadingState,
    List<ProductDetails>? subscriptionPlans,
    String? errorMessage,
    bool clearError = false,
    bool? subscriptionExpired,
    bool? showExpiredBanner,
    bool? wasEverSubscriber,
  }) {
    return PremiumState(
      status: status ?? this.status,
      loadingState: loadingState ?? this.loadingState,
      subscriptionPlans: subscriptionPlans ?? this.subscriptionPlans,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      subscriptionExpired: subscriptionExpired ?? this.subscriptionExpired,
      showExpiredBanner: showExpiredBanner ?? this.showExpiredBanner,
      wasEverSubscriber: wasEverSubscriber ?? this.wasEverSubscriber,
    );
  }
}