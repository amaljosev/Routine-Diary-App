import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  static const String _keyShowOnboarding = 'showOnboarding';

  @override
  Future<bool> shouldShowOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowOnboarding) ?? true;
  }

  @override
  Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowOnboarding, false);
  }
}