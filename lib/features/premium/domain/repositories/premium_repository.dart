
import 'package:fpdart/fpdart.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:routine/core/error/subscription/sub_failures.dart';
import 'package:routine/features/premium/domain/entities/premium_status.dart';

abstract class PremiumRepository {
  /// Read locally cached premium status. Fast, no network.
  Future<Either<StorageFailure, PremiumStatus>> getCachedStatus();
 
  /// Persist that the user has unlocked premium.
  Future<Either<StorageFailure, Unit>> savePremiumUnlocked();
 
  /// Fetch ALL subscription plans from the store (monthly, 3-month, yearly).
  /// Returns a list — empty list on failure is handled by the bloc.
  Future<Either<StoreUnavailableFailure, List<ProductDetails>>> fetchProductDetails();
 
  /// Open the OS purchase sheet for the selected plan.
  Future<Either<PremiumFailure, Unit>> buyPremium(ProductDetails product);
 
  /// Ask the store to restore past purchases.
  Future<Either<PremiumFailure, Unit>> restorePurchases();
 
  /// Stream of purchase outcomes from the IAP plugin.
  Stream<Either<PremiumFailure, Unit>> get purchaseResultStream;
}