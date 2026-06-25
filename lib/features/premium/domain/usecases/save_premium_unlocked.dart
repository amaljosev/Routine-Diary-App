// lib/features/premium/domain/usecases/save_premium_unlocked.dart

import 'package:fpdart/fpdart.dart';
import 'package:routine/core/error/subscription/sub_failures.dart';
import 'package:routine/features/premium/domain/repositories/premium_repository.dart';

class SavePremiumUnlocked {
  final PremiumRepository _repository;
  const SavePremiumUnlocked(this._repository);
 
  Future<Either<StorageFailure, Unit>> call() =>
      _repository.savePremiumUnlocked();
}
