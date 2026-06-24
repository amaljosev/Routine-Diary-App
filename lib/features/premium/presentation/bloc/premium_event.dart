part of 'premium_bloc.dart';


sealed class PremiumEvent {
  const PremiumEvent();
}

/// Dispatched at startup — loads local cache + fetches product price.
class PremiumStarted extends PremiumEvent {
  const PremiumStarted();
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

/// Internal — emitted when the IAP stream reports failure/cancel.
class PremiumPurchaseFailed extends PremiumEvent {
  final String message;
  const PremiumPurchaseFailed(this.message);
}