// lib/features/premium/data/repositories/premium_repository_impl.dart

import 'package:fpdart/fpdart.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:routine/core/error/subscription/sub_failures.dart';
import '../../domain/entities/premium_status.dart';
import '../../domain/repositories/premium_repository.dart';
import '../datasources/premium_iap_datasource.dart';
import '../datasources/premium_local_datasource.dart';

class PremiumRepositoryImpl implements PremiumRepository {
  final PremiumLocalDataSource _local;
  final PremiumIapDataSource _iap;

  const PremiumRepositoryImpl({
    required PremiumLocalDataSource local,
    required PremiumIapDataSource iap,
  })  : _local = local,
        _iap = iap;

  @override
  Future<Either<StorageFailure, PremiumStatus>> getCachedStatus() async {
    try {
      final unlocked = await _local.isPremiumUnlocked();
      return right(
        unlocked ? const PremiumStatus.premium() : const PremiumStatus.free(),
      );
    } catch (e) {
      return left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<StorageFailure, Unit>> savePremiumUnlocked() async {
    try {
      await _local.setPremiumUnlocked();
      return right(unit);
    } catch (e) {
      return left(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<StorageFailure, Unit>> clearPremiumCache() async {
    try {
      await _local.clearPremiumUnlocked();
      return right(unit);
    } catch (e) {
      return left(StorageFailure(e.toString()));
    }
  }

  /// Returns true if the user has ever held a subscription.
  /// This value is never cleared — safe to use for lapsed-subscriber UX.
  @override
  Future<bool> wasEverSubscriber() => _local.wasEverSubscriber();

  @override
  Future<bool> verifySubscription() => _iap.verifyActiveSubscription();

  @override
  Future<Either<StoreUnavailableFailure, List<ProductDetails>>>
      fetchProductDetails() async {
    final plans = await _iap.fetchProductDetails();
    if (plans.isEmpty) return left(const StoreUnavailableFailure());
    return right(plans);
  }

  @override
  Future<Either<PremiumFailure, Unit>> buyPremium(
    ProductDetails product,
  ) async {
    try {
      await _iap.buyNonConsumable(product);
      return right(unit);
    } catch (e) {
      return left(PurchaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<PremiumFailure, Unit>> restorePurchases() async {
    try {
      await _iap.restorePurchases();
      return right(unit);
    } catch (e) {
      return left(PurchaseFailure(e.toString()));
    }
  }

  @override
  Stream<Either<PremiumFailure, Unit>> get purchaseResultStream =>
      _iap.resultStream.map(
        (raw) => switch (raw) {
          RawPurchaseSuccess() => right(unit),
          RawPurchaseFailure(:final message, :final isCancellation) => left(
              isCancellation
                  ? PurchaseCancelledFailure()
                  : PurchaseFailure(message),
            ),
        },
      );
}