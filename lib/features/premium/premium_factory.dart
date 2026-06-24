// lib/features/premium/premium_factory.dart
import 'package:routine/features/premium/domain/usecases/fetch_product_details.dart';
import 'package:routine/features/premium/domain/usecases/get_premium_status.dart';
import 'package:routine/features/premium/domain/usecases/purchase_premium.dart';
import 'package:routine/features/premium/domain/usecases/restore_purchases.dart';
import 'package:routine/features/premium/domain/usecases/save_premium_unlocked.dart';

import 'data/datasources/premium_iap_datasource.dart';
import 'data/datasources/premium_local_datasource.dart';
import 'data/repositories/premium_repository_impl.dart';
import 'presentation/bloc/premium_bloc.dart';

class PremiumFactory {
  PremiumFactory._();


  static PremiumBloc createBloc() {
    // Data layer
    final local = PremiumLocalDataSource();
    final iap = PremiumIapDataSource.instance;
    final repository = PremiumRepositoryImpl(local: local, iap: iap);

    // Use cases
    final getStatus = GetPremiumStatus(repository);
    final fetchProduct = FetchProductDetails(repository);
    final purchase = PurchasePremium(repository);
    final restore = RestorePurchases(repository);
    final saveUnlocked = SavePremiumUnlocked(repository);

    // Bloc
    return PremiumBloc(
      getStatus: getStatus,
      fetchProduct: fetchProduct,
      purchase: purchase,
      restore: restore,
      saveUnlocked: saveUnlocked,
      repository: repository,
    );
  }
}
