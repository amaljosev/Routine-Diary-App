// lib/features/premium/domain/usecases/get_premium_status.dart
import 'package:fpdart/fpdart.dart';
import 'package:routine/core/error/subscription/sub_failures.dart';
import 'package:routine/features/premium/domain/entities/premium_status.dart';
import 'package:routine/features/premium/domain/repositories/premium_repository.dart';

class GetPremiumStatus {
  final PremiumRepository _repository;
  const GetPremiumStatus(this._repository);
 
  Future<Either<StorageFailure, PremiumStatus>> call() =>
      _repository.getCachedStatus();
}
