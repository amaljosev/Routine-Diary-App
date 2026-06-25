// lib/features/premium/domain/usecases/purchase_premium.dart
import 'package:fpdart/fpdart.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:routine/core/error/subscription/sub_failures.dart';
import 'package:routine/features/premium/domain/repositories/premium_repository.dart';

class PurchasePremium {
  final PremiumRepository _repository;
  const PurchasePremium(this._repository);
 
  Future<Either<PremiumFailure, Unit>> call(ProductDetails product) =>
      _repository.buyPremium(product);
}