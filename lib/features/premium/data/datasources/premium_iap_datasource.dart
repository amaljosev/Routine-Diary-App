import 'dart:async';
import 'dart:developer';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:routine/core/constants/app_constants.dart';



/// Wraps the [InAppPurchase] plugin.
/// Emits [RawPurchaseResult] values that the repository maps to domain types.
class PremiumIapDataSource {
  PremiumIapDataSource._();
  static final PremiumIapDataSource instance = PremiumIapDataSource._();

  final InAppPurchase _iap = InAppPurchase.instance;

  // Store subscription so it can be cancelled on re-init / dispose
  StreamSubscription<List<PurchaseDetails>>? _iapSub;

  final _resultController = StreamController<RawPurchaseResult>.broadcast();
  Stream<RawPurchaseResult> get resultStream => _resultController.stream;

  /// Call once in main.dart before runApp.
  void init() {
    _iapSub?.cancel();
    _iapSub = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (e) => log('IAP stream error: $e'),
    );
  }

  void dispose() {
    _iapSub?.cancel();
    _resultController.close();
  }

  // ── Fetch all plans ───────────────────────────────────────────────────────

  /// Returns all found subscription plans. Empty list if store unavailable.
  Future<List<ProductDetails>> fetchProductDetails() async {
    final available = await _iap.isAvailable();
    if (!available) {
      log('IAP: Store not available');
      return [];
    }

    final response = await _iap.queryProductDetails(AppConstants.kPremiumProductIds);

    if (response.error != null) {
      log('IAP query error: ${response.error}');
      return [];
    }

    if (response.productDetails.isEmpty) {
      log('IAP: No products found. notFoundIDs: ${response.notFoundIDs}');
      return [];
    }

    // Sort by duration: monthly → 3-month → yearly
    final sorted = [...response.productDetails]..sort((a, b) {
        int order(String id) {
          if (id.contains('monthly')) return 0;
          if (id.contains('3month')) return 1;
          return 2; // yearly
        }
        return order(a.id).compareTo(order(b.id));
      });

    return sorted;
  }

  // ── Purchase / Restore ────────────────────────────────────────────────────

  Future<void> buyNonConsumable(ProductDetails product) =>
      _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );

  Future<void> restorePurchases() => _iap.restorePurchases();

  // ── Internal stream handler ───────────────────────────────────────────────

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final p in purchases) {
      // Match any of the 3 plan IDs
      if (!AppConstants.kPremiumProductIds.contains(p.productID)) continue;

      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _resultController.add(const RawPurchaseSuccess());
          if (p.pendingCompletePurchase) _iap.completePurchase(p);

        case PurchaseStatus.error:
          final msg = p.error?.message ?? 'Unknown IAP error';
          log('IAP error: $msg');
          _resultController.add(RawPurchaseFailure(msg));
          if (p.pendingCompletePurchase) _iap.completePurchase(p);

        case PurchaseStatus.canceled:
          _resultController.add(const RawPurchaseFailure('Purchase cancelled'));

        case PurchaseStatus.pending:
          break;
      }
    }
  }
}

// ── Public result types ───────────────────────────────────────────────────────

sealed class RawPurchaseResult {
  const RawPurchaseResult();
}

final class RawPurchaseSuccess extends RawPurchaseResult {
  const RawPurchaseSuccess();
}

final class RawPurchaseFailure extends RawPurchaseResult {
  final String message;
  const RawPurchaseFailure(this.message);
}