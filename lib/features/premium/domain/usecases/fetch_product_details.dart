// lib/features/premium/domain/usecases/fetch_product_details.dart
import 'package:fpdart/fpdart.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:routine/core/error/subscription/sub_failures.dart';
import 'package:routine/features/premium/domain/repositories/premium_repository.dart';

class FetchProductDetails {
  final PremiumRepository _repository;
  const FetchProductDetails(this._repository);
 
  Future<Either<StoreUnavailableFailure, List<ProductDetails>>> call() =>
      _repository.fetchProductDetails();
}