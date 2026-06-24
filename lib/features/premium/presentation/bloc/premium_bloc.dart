import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:routine/features/premium/domain/repositories/premium_repository.dart';
import 'package:routine/features/premium/domain/usecases/fetch_product_details.dart';
import 'package:routine/features/premium/domain/usecases/get_premium_status.dart';
import 'package:routine/features/premium/domain/usecases/purchase_premium.dart';
import 'package:routine/features/premium/domain/usecases/restore_purchases.dart';
import 'package:routine/features/premium/domain/usecases/save_premium_unlocked.dart';
import '../../domain/entities/premium_status.dart';
part 'premium_event.dart';
part 'premium_state.dart';


class PremiumBloc extends Bloc<PremiumEvent, PremiumState> {
  final GetPremiumStatus _getStatus;
  final FetchProductDetails _fetchProduct;
  final PurchasePremium _purchase;
  final RestorePurchases _restore;
  final SavePremiumUnlocked _saveUnlocked;
 
  StreamSubscription<dynamic>? _purchaseSub;
 
  PremiumBloc({
    required GetPremiumStatus getStatus,
    required FetchProductDetails fetchProduct,
    required PurchasePremium purchase,
    required RestorePurchases restore,
    required SavePremiumUnlocked saveUnlocked,
    required PremiumRepository repository,
  })  : _getStatus = getStatus,
        _fetchProduct = fetchProduct,
        _purchase = purchase,
        _restore = restore,
        _saveUnlocked = saveUnlocked,
        super(const PremiumState()) {
    _purchaseSub = repository.purchaseResultStream.listen((either) {
      either.fold(
        (failure) => add(PremiumPurchaseFailed(failure.message)),
        (_) => add(const PremiumPurchaseSucceeded()),
      );
    });
 
    on<PremiumStarted>(_onStarted);
    on<PremiumPurchaseRequested>(_onPurchaseRequested);
    on<PremiumRestoreRequested>(_onRestoreRequested);
    on<PremiumPurchaseSucceeded>(_onSucceeded);
    on<PremiumPurchaseFailed>(_onFailed);
  }
 
  // ── Handlers ──────────────────────────────────────────────────────────────
 
  Future<void> _onStarted(
    PremiumStarted _,
    Emitter<PremiumState> emit,
  ) async {
    emit(state.copyWith(loadingState: PremiumLoadingState.loading));
 
    // 1. Check local cache
    final statusResult = await _getStatus();
    final status = statusResult.fold(
      (_) => state.status, // storage error → keep current (free)
      (s) => s,
    );
 
    if (status.isPremium) {
      emit(state.copyWith(
        status: status,
        loadingState: PremiumLoadingState.idle,
      ));
      return; // Already premium — skip fetching plans
    }
 
    // 2. Fetch all 3 subscription plans from the store
    final plansResult = await _fetchProduct();
    final plans = plansResult.fold((_) => <dynamic>[], (p) => p);
 
    emit(state.copyWith(
      status: status,
      loadingState: PremiumLoadingState.idle,
      // plans is List<ProductDetails> returned from fetchProductDetails
      subscriptionPlans: List.from(plans),
    ));
  }
 
  Future<void> _onPurchaseRequested(
    PremiumPurchaseRequested event,
    Emitter<PremiumState> emit,
  ) async {
    emit(state.copyWith(
      loadingState: PremiumLoadingState.purchasing,
      errorMessage: null,
    ));
 
    // event.product is whichever plan the user selected (monthly/3month/yearly)
    final result = await _purchase(event.product);
    result.fold(
      (failure) => emit(state.copyWith(
        loadingState: PremiumLoadingState.idle,
        errorMessage: failure.message,
      )),
      (_) {
        // Success arrives via purchaseResultStream → PremiumPurchaseSucceeded
      },
    );
  }
 
  Future<void> _onRestoreRequested(
    PremiumRestoreRequested _,
    Emitter<PremiumState> emit,
  ) async {
    emit(state.copyWith(
      loadingState: PremiumLoadingState.purchasing,
      errorMessage: null,
    ));
 
    final result = await _restore();
    result.fold(
      (failure) => emit(state.copyWith(
        loadingState: PremiumLoadingState.idle,
        errorMessage: failure.message,
      )),
      (_) {
        // Restore result arrives via purchaseResultStream
      },
    );
  }
 
  Future<void> _onSucceeded(
    PremiumPurchaseSucceeded _,
    Emitter<PremiumState> emit,
  ) async {
    // Trust the purchase stream — set premium immediately.
    // Don't re-read cache; a save failure shouldn't show user as free.
    await _saveUnlocked(); // best-effort persist
 
    emit(state.copyWith(
      status: const PremiumStatus.premium(),
      loadingState: PremiumLoadingState.idle,
      errorMessage: null,
    ));
  }
 
  void _onFailed(
    PremiumPurchaseFailed event,
    Emitter<PremiumState> emit,
  ) {
    emit(state.copyWith(
      loadingState: PremiumLoadingState.idle,
      errorMessage: event.message,
    ));
  }
 
  @override
  Future<void> close() {
    _purchaseSub?.cancel();
    return super.close();
  }
}