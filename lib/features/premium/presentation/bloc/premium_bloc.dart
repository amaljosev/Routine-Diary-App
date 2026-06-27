// lib/features/premium/presentation/bloc/premium_bloc.dart
import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:routine/core/error/subscription/sub_failures.dart';
import 'package:routine/features/premium/domain/repositories/premium_repository.dart';
import 'package:routine/features/premium/domain/usecases/clear_premium_cache.dart';
import 'package:routine/features/premium/domain/usecases/fetch_product_details.dart';
import 'package:routine/features/premium/domain/usecases/get_premium_status.dart';
import 'package:routine/features/premium/domain/usecases/purchase_premium.dart';
import 'package:routine/features/premium/domain/usecases/restore_purchases.dart';
import 'package:routine/features/premium/domain/usecases/save_premium_unlocked.dart';
import 'package:routine/features/premium/domain/usecases/verify_subscription.dart';
import '../../domain/entities/premium_status.dart';

part 'premium_event.dart';
part 'premium_state.dart';

class PremiumBloc extends Bloc<PremiumEvent, PremiumState> {
  final GetPremiumStatus _getStatus;
  final FetchProductDetails _fetchProduct;
  final PurchasePremium _purchase;
  final RestorePurchases _restore;
  final SavePremiumUnlocked _saveUnlocked;
  final VerifySubscription _verifySubscription;
  final ClearPremiumCache _clearPremiumCache;
  final PremiumRepository _repository;

  StreamSubscription<dynamic>? _purchaseSub;

  PremiumBloc({
    required GetPremiumStatus getStatus,
    required FetchProductDetails fetchProduct,
    required PurchasePremium purchase,
    required RestorePurchases restore,
    required SavePremiumUnlocked saveUnlocked,
    required VerifySubscription verifySubscription,
    required ClearPremiumCache clearPremiumCache,
    required PremiumRepository repository,
  })  : _getStatus = getStatus,
        _fetchProduct = fetchProduct,
        _purchase = purchase,
        _restore = restore,
        _saveUnlocked = saveUnlocked,
        _verifySubscription = verifySubscription,
        _clearPremiumCache = clearPremiumCache,
        _repository = repository,
        super(const PremiumState()) {
          
    _purchaseSub = repository.purchaseResultStream.listen((either) {
      either.fold(
        (failure) {
          // Check if the failure type maps to a cancellation
          final isCancel = failure is PurchaseCancelledFailure;
          
          add(PremiumPurchaseFailed(
            failure.message,
            isCancellation: isCancel, // Pass the flag to the event
          ));
        },
        (_) => add(const PremiumPurchaseSucceeded()),
      );
    });

    on<PremiumStarted>(_onStarted);
    on<PremiumPurchaseRequested>(_onPurchaseRequested);
    on<PremiumRestoreRequested>(_onRestoreRequested);
    on<PremiumPurchaseSucceeded>(_onSucceeded);
    on<PremiumPurchaseFailed>(_onFailed);
    on<PremiumPurchaseReset>(_onReset);
    on<PremiumSubscriptionExpired>(_onExpired);
    on<PremiumExpiredBannerShown>(_onExpiredBannerShown);
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  Future<void> _onStarted(
    PremiumStarted _,
    Emitter<PremiumState> emit,
  ) async {
    emit(state.copyWith(loadingState: PremiumLoadingState.loading));

    // Load wasEverSubscriber alongside premium status — both come from local
    // storage so this is fast and offline-safe.
    final statusResult = await _getStatus();
    final status = statusResult.fold((_) => state.status, (s) => s);
    final wasEver = await _repository.wasEverSubscriber();

    if (status.isPremium) {
      // Emit premium state immediately so the UI is responsive.
      emit(state.copyWith(
        status: status,
        loadingState: PremiumLoadingState.idle,
        wasEverSubscriber: wasEver,
      ));

      log('🔍 Premium cached — verifying with store...');

      bool isStillActive = true;
      try {
        isStillActive = await _verifySubscription();
      } catch (e) {
        log('⚠️ verifySubscription threw unexpectedly: $e → benefit of doubt');
        isStillActive = true;
      }

      if (!isStillActive) {
        log('⚠️ Subscription expired — revoking premium access');
        Future.microtask(() => add(const PremiumSubscriptionExpired()));
      } else {
        log('✅ Subscription still active');
      }
      return;
    }

    // Not premium locally — load plans for paywall.
    final plansResult = await _fetchProduct();
    final plans = plansResult.fold(
      (failure) {
        log('❌ FetchProductDetails failed: ${failure.message}');
        return <ProductDetails>[];
      },
      (p) {
        log('✅ Plans fetched: ${p.map((e) => e.id).toList()}');
        return p;
      },
    );

    emit(state.copyWith(
      status: status,
      loadingState: PremiumLoadingState.idle,
      subscriptionPlans: List.from(plans),
      wasEverSubscriber: wasEver,
    ));
  }

  Future<void> _onExpired(
    PremiumSubscriptionExpired _,
    Emitter<PremiumState> emit,
  ) async {
    await _clearPremiumCache();

    // wasEverSubscriber remains true — subscription lapsed, not forgotten.
    emit(state.copyWith(
      status: const PremiumStatus.free(),
      loadingState: PremiumLoadingState.loading,
      clearError: true,
      subscriptionExpired: true,
      showExpiredBanner: true,
      // wasEverSubscriber is intentionally left as-is (already true)
    ));

    final plansResult = await _fetchProduct();
    final plans = plansResult.fold(
      (failure) {
        log('❌ FetchProductDetails after expiry failed: ${failure.message}');
        return <ProductDetails>[];
      },
      (p) => p,
    );

    emit(state.copyWith(
      loadingState: PremiumLoadingState.idle,
      subscriptionPlans: List.from(plans),
      subscriptionExpired: true,
      showExpiredBanner: true,
    ));
  }

  Future<void> _onPurchaseRequested(
    PremiumPurchaseRequested event,
    Emitter<PremiumState> emit,
  ) async {
    emit(state.copyWith(
      loadingState: PremiumLoadingState.purchasing,
      clearError: true,
    ));

    final result = await _purchase(event.product);
    result.fold(
      (failure) => emit(state.copyWith(
        loadingState: PremiumLoadingState.idle,
        errorMessage: failure.message,
      )),
      (_) {
        // OS purchase sheet is showing — result arrives via purchaseResultStream.
      },
    );
  }

  Future<void> _onRestoreRequested(
    PremiumRestoreRequested _,
    Emitter<PremiumState> emit,
  ) async {
    emit(state.copyWith(
      loadingState: PremiumLoadingState.purchasing,
      clearError: true,
    ));

    final result = await _restore();
    result.fold(
      (failure) => emit(state.copyWith(
        loadingState: PremiumLoadingState.idle,
        errorMessage: failure.message,
      )),
      (_) {
        // Result arrives via purchaseResultStream.
      },
    );
  }

  Future<void> _onSucceeded(
    PremiumPurchaseSucceeded _,
    Emitter<PremiumState> emit,
  ) async {
    await _saveUnlocked();

    // Re-read wasEverSubscriber — it was just stamped by saveUnlocked →
    // setPremiumUnlocked → also sets kWasEverSubscriber.
    final wasEver = await _repository.wasEverSubscriber();

    emit(state.copyWith(
      status: const PremiumStatus.premium(),
      loadingState: PremiumLoadingState.idle,
      clearError: true,
      subscriptionExpired: false,
      showExpiredBanner: false,
      wasEverSubscriber: wasEver,
    ));
  }

  void _onFailed(
    PremiumPurchaseFailed event,
    Emitter<PremiumState> emit,
  ) {
    log('❌ Purchase failed/cancelled: ${event.message}');
    emit(state.copyWith(
      loadingState: PremiumLoadingState.idle,
      errorMessage: event.isCancellation ? null : event.message,
      clearError: event.isCancellation,
    ));
  }

  void _onReset(
    PremiumPurchaseReset _,
    Emitter<PremiumState> emit,
  ) {
    if (state.isPurchasing) {
      log('⚠️ Paywall closed while purchasing — resetting state');
      emit(state.copyWith(
        loadingState: PremiumLoadingState.idle,
        clearError: true,
      ));
    }
  }

  void _onExpiredBannerShown(
    PremiumExpiredBannerShown _,
    Emitter<PremiumState> emit,
  ) {
    emit(state.copyWith(showExpiredBanner: false));
  }

  @override
  Future<void> close() {
    _purchaseSub?.cancel();
    return super.close();
  }
}