// lib/features/premium/domain/repositories/premium_repository.dart

import 'package:fpdart/fpdart.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:routine/core/error/subscription/sub_failures.dart';
import 'package:routine/features/premium/domain/entities/premium_status.dart';

abstract class PremiumRepository {
  /// Read locally cached premium status. Fast, no network.
  Future<Either<StorageFailure, PremiumStatus>> getCachedStatus();

  /// Persist that the user has unlocked premium.
  Future<Either<StorageFailure, Unit>> savePremiumUnlocked();

  /// Remove the local premium flag.
  /// Called when the store confirms the subscription has lapsed.
  Future<Either<StorageFailure, Unit>> clearPremiumCache();

  /// Ask the store whether the user still has an active subscription.
  ///
  /// Returns [true]  → subscription is active (keep premium).
  /// Returns [false] → store responded; no active subscription found (revoke).
  ///
  /// On store unavailability or any error this returns [true] to give the
  /// user benefit of the doubt rather than incorrectly revoking access.
  Future<bool> verifySubscription();

  /// Fetch ALL subscription plans from the store.
  Future<Either<StoreUnavailableFailure, List<ProductDetails>>>
      fetchProductDetails();

  /// Open the OS purchase sheet for the selected plan.
  Future<Either<PremiumFailure, Unit>> buyPremium(ProductDetails product);

  /// Ask the store to restore past purchases.
  Future<Either<PremiumFailure, Unit>> restorePurchases();

  /// Stream of purchase outcomes from the IAP plugin.
  Stream<Either<PremiumFailure, Unit>> get purchaseResultStream;

  Future<bool> wasEverSubscriber();
}
