// lib/features/premium/data/datasources/premium_iap_datasource.dart
import 'dart:async';
import 'dart:developer';
import 'dart:io' show Platform;

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:routine/core/constants/app_constants.dart';

class PremiumIapDataSource {
  PremiumIapDataSource._();
  static final PremiumIapDataSource instance = PremiumIapDataSource._();

  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _iapSub;

  final _resultController = StreamController<RawPurchaseResult>.broadcast();
  Stream<RawPurchaseResult> get resultStream => _resultController.stream;

  // iOS-only verify completer — reuses the existing _iapSub, no second listener.
  Completer<bool>? _iosVerifyCompleter;

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
    _iosVerifyCompleter = null;
  }

  // ── Fetch all plans ───────────────────────────────────────────────────────

  Future<List<ProductDetails>> fetchProductDetails() async {
    final available = await _iap.isAvailable();
    if (!available) {
      log('IAP: Store not available');
      return [];
    }

    final response = await _iap.queryProductDetails(
      AppConstants.kPremiumProductIds,
    );

    if (response.error != null) {
      log('IAP query error: ${response.error}');
      return [];
    }

    if (response.productDetails.isEmpty) {
      log('IAP: No products found. notFoundIDs: ${response.notFoundIDs}');
      return [];
    }

    List<ProductDetails> plans = response.productDetails;

    if (Platform.isAndroid) {
      plans = _filterAndSortAndroid(plans);
    } else {
      plans = [...plans]..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
    }

    log('IAP: ${plans.length} active plans: '
        '${plans.map((p) => basePlanId(p) ?? p.id).toList()}');

    return plans;
  }

  List<ProductDetails> _filterAndSortAndroid(List<ProductDetails> raw) {
    final result = <ProductDetails>[];
    for (final p in raw) {
      // Inactive base plans have no price — skip them.
      if (p.rawPrice <= 0) {
        log('IAP: Skipping "${basePlanId(p)}" (inactive — no price)');
        continue;
      }
      result.add(p);
    }
    result.sort((a, b) {
      int order(ProductDetails p) {
        final bpId = basePlanId(p)?.toLowerCase() ?? '';
        if (bpId.contains('monthly')) return 0;
        if (bpId.contains('quarter') || bpId.contains('3month')) return 1;
        return 2;
      }
      return order(a).compareTo(order(b));
    });
    return result;
  }

  // ── Purchase / Restore ────────────────────────────────────────────────────

  Future<void> buyNonConsumable(ProductDetails product) =>
      _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );

  Future<void> restorePurchases() => _iap.restorePurchases();

  // ── Subscription verification ─────────────────────────────────────────────
  //
  // Android: queryPastPurchases via InAppPurchaseAndroidPlatformAddition.
  //   Queries local Play billing cache — fast, offline-safe, no stream events.
  //   Requires in_app_purchase_android as explicit pubspec dependency.
  //
  // iOS: restorePurchases + stream via existing _iapSub.
  //   Silent, no UI shown. _iosVerifyCompleter is completed by _onPurchaseUpdate.
  //
  // All error paths → true (benefit of the doubt — never wrongly revoke access).

  Future<bool> verifyActiveSubscription() async {
    try {
      final available =
          await _iap.isAvailable().timeout(const Duration(seconds: 4));
      if (!available) {
        log('IAP verify: store not available → benefit of doubt');
        return true;
      }
    } catch (e) {
      log('IAP verify: availability check failed ($e) → benefit of doubt');
      return true;
    }

    return Platform.isAndroid ? _verifyAndroid() : _verifyIos();
  }

  Future<bool> _verifyAndroid() async {
    try {
      final addition =
          _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();

      final response = await addition
          .queryPastPurchases()
          .timeout(const Duration(seconds: 6));

      if (response.error != null) {
        log('IAP verify [Android]: error ${response.error!.message} '
            '→ benefit of doubt');
        return true;
      }

      final hasActive = response.pastPurchases.any(
        (p) =>
            AppConstants.kPremiumProductIds.contains(p.productID) &&
            p.status == PurchaseStatus.purchased,
      );

      log('IAP verify [Android]: hasActive=$hasActive '
          '(${response.pastPurchases.length} purchases checked)');

      return hasActive;
    } catch (e) {
      log('IAP verify [Android]: exception ($e) → benefit of doubt');
      return true;
    }
  }

  Future<bool> _verifyIos() async {
    if (_iosVerifyCompleter != null && !_iosVerifyCompleter!.isCompleted) {
      return _iosVerifyCompleter!.future;
    }
    _iosVerifyCompleter = Completer<bool>();

    log('IAP verify [iOS]: calling restorePurchases...');
    try {
      await _iap.restorePurchases();
    } catch (e) {
      log('IAP verify [iOS]: threw ($e) → benefit of doubt');
      _iosVerifyCompleter!.complete(true);
      return _iosVerifyCompleter!.future;
    }

    return _iosVerifyCompleter!.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        log('IAP verify [iOS]: timed out → benefit of doubt');
        return true;
      },
    );
  }

  // ── Internal stream handler ───────────────────────────────────────────────

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final p in purchases) {
      if (!AppConstants.kPremiumProductIds.contains(p.productID)) continue;

      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          log('IAP: Purchase/restore success for ${p.productID}');

          if (_iosVerifyCompleter != null &&
              !_iosVerifyCompleter!.isCompleted) {
            // This is an iOS verification response — complete the completer,
            // do NOT also send to _resultController (not a user-initiated purchase).
            log('IAP verify [iOS]: confirmed active');
            _iosVerifyCompleter!.complete(true);
          } else {
            // Normal user-initiated purchase or restore.
            _resultController.add(const RawPurchaseSuccess());
          }

          if (p.pendingCompletePurchase) _iap.completePurchase(p);

        case PurchaseStatus.error:
          final msg = p.error?.message ?? 'Unknown IAP error';
          log('IAP error: $msg');

          if (_iosVerifyCompleter != null &&
              !_iosVerifyCompleter!.isCompleted) {
            log('IAP verify [iOS]: error → not active');
            _iosVerifyCompleter!.complete(false);
          } else {
            _resultController.add(RawPurchaseFailure(msg, isCancellation: false));
          }
          if (p.pendingCompletePurchase) _iap.completePurchase(p);

        case PurchaseStatus.canceled:
          log('IAP: Purchase cancelled for ${p.productID}');
          if (_iosVerifyCompleter == null || _iosVerifyCompleter!.isCompleted) {
            _resultController.add(
              const RawPurchaseFailure('Purchase cancelled', isCancellation: true),
            );
          }

        case PurchaseStatus.pending:
          log('IAP: Purchase pending for ${p.productID}');
          break;
      }
    }
  }
}

// ── Base plan ID helper ───────────────────────────────────────────────────────

String? basePlanId(ProductDetails details) {
  if (details is! GooglePlayProductDetails) return null;
  return details.productDetails.subscriptionOfferDetails?.firstOrNull
      ?.basePlanId;
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
  final bool isCancellation;
  const RawPurchaseFailure(this.message, {this.isCancellation = false});
}