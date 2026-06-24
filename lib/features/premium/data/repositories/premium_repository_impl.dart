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
  }) : _local = local,
       _iap = iap;

  // ── getCachedStatus ───────────────────────────────────────────────────────

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

  // ── savePremiumUnlocked ───────────────────────────────────────────────────

  @override
  Future<Either<StorageFailure, Unit>> savePremiumUnlocked() async {
    try {
      await _local.setPremiumUnlocked();
      return right(unit);
    } catch (e) {
      return left(StorageFailure(e.toString()));
    }
  }

  // ── fetchProductDetails ───────────────────────────────────────────────────
  // Returns all 3 subscription plans as a list.

  @override
  Future<Either<StoreUnavailableFailure, List<ProductDetails>>>
  fetchProductDetails() async {
    final plans = await _iap.fetchProductDetails();
    if (plans.isEmpty) return left(const StoreUnavailableFailure());
    return right(plans);
  }

  // ── buyPremium ────────────────────────────────────────────────────────────

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

  // ── restorePurchases ──────────────────────────────────────────────────────

  @override
  Future<Either<PremiumFailure, Unit>> restorePurchases() async {
    try {
      await _iap.restorePurchases();
      return right(unit);
    } catch (e) {
      return left(PurchaseFailure(e.toString()));
    }
  }

  // ── purchaseResultStream ──────────────────────────────────────────────────

  @override
  Stream<Either<PremiumFailure, Unit>> get purchaseResultStream =>
      _iap.resultStream.map(
        (raw) => switch (raw) {
          RawPurchaseSuccess() => right(unit),
          RawPurchaseFailure(:final message) => left(PurchaseFailure(message)),
        },
      );
}
