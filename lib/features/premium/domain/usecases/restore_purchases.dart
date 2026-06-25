
// lib/features/premium/domain/usecases/restore_purchases.dart
import 'package:fpdart/fpdart.dart';
import 'package:routine/core/error/subscription/sub_failures.dart';
import 'package:routine/features/premium/domain/repositories/premium_repository.dart';

class RestorePurchases {
  final PremiumRepository _repository;
  const RestorePurchases(this._repository);
 
  Future<Either<PremiumFailure, Unit>> call() =>
      _repository.restorePurchases();
}