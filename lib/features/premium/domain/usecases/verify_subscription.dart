// lib/features/premium/domain/usecases/verify_subscription.dart

import 'package:routine/features/premium/domain/repositories/premium_repository.dart';

/// Asks the store whether the user's subscription is still active.
///
/// Returns [true]  → active, keep premium.
/// Returns [false] → expired/not found, revoke premium.
///
/// Errors and store unavailability resolve to [true] (benefit of doubt).
class VerifySubscription {
  final PremiumRepository _repository;
  const VerifySubscription(this._repository);

  Future<bool> call() => _repository.verifySubscription();
}
