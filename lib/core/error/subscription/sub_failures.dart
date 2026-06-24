
sealed class PremiumFailure {
  final String message;
  const PremiumFailure(this.message);
}
 
final class StoreUnavailableFailure extends PremiumFailure {
  const StoreUnavailableFailure() : super('Store is not available');
}
 
final class PurchaseCancelledFailure extends PremiumFailure {
  const PurchaseCancelledFailure() : super('Purchase cancelled');
}
 
final class PurchaseFailure extends PremiumFailure {
  const PurchaseFailure(super.message);
}
 
final class StorageFailure extends PremiumFailure {
  const StorageFailure(super.message);
}