// lib/features/premium/presentation/bloc/premium_event.dart
part of 'premium_bloc.dart';

sealed class PremiumEvent {
  const PremiumEvent();
}

/// Dispatched at startup — loads local cache and fetches product prices.
/// Store verification is intentionally NOT triggered here to avoid blocking
/// the render thread. See [PremiumVerifyRequested].
class PremiumStarted extends PremiumEvent {
  const PremiumStarted();
}

/// Dispatched after the first frame via addPostFrameCallback.
/// Runs the background store verification safely off the render thread.
class PremiumVerifyRequested extends PremiumEvent {
  const PremiumVerifyRequested();
}

/// User tapped the purchase button on the paywall.
class PremiumPurchaseRequested extends PremiumEvent {
  final ProductDetails product;
  const PremiumPurchaseRequested(this.product);
}

/// User tapped "Restore Purchase".
class PremiumRestoreRequested extends PremiumEvent {
  const PremiumRestoreRequested();
}

/// Internal — emitted when the IAP stream reports success.
class PremiumPurchaseSucceeded extends PremiumEvent {
  const PremiumPurchaseSucceeded();
}

/// Internal — emitted when the IAP stream reports failure or cancellation.
/// [isCancellation] suppresses the error snackbar.
class PremiumPurchaseFailed extends PremiumEvent {
  final String message;
  final bool isCancellation;
  const PremiumPurchaseFailed(this.message, {this.isCancellation = false});
}

/// Dispatched by the UI when the paywall sheet closes/disposes.
/// Resets the purchasing loading state if the IAP stream never fired.
class PremiumPurchaseReset extends PremiumEvent {
  const PremiumPurchaseReset();
}

/// Internal — dispatched when the store confirms the locally cached premium
/// subscription is no longer active. Triggers local cache clear and,
/// via main.dart BlocListener, resets the custom theme to index 0.
class PremiumSubscriptionExpired extends PremiumEvent {
  const PremiumSubscriptionExpired();
}

/// Dispatched by the UI after it has shown the "subscription expired" banner.
/// Resets [PremiumState.showExpiredBanner] so the banner doesn't re-appear.
class PremiumExpiredBannerShown extends PremiumEvent {
  const PremiumExpiredBannerShown();
}