// lib/features/premium/domain/usecases/clear_premium_cache.dart
import 'package:fpdart/fpdart.dart';
import 'package:routine/core/error/subscription/sub_failures.dart';
import 'package:routine/features/premium/domain/repositories/premium_repository.dart';

/// Removes the locally cached premium flag.
/// Called by [PremiumBloc] when the store confirms the subscription has lapsed.
class ClearPremiumCache {
  final PremiumRepository _repository;
  const ClearPremiumCache(this._repository);

  Future<Either<StorageFailure, Unit>> call() =>
      _repository.clearPremiumCache();
}
