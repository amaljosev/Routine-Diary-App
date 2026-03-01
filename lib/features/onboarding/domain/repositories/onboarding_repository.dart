abstract class OnboardingRepository {
  Future<bool> shouldShowOnboarding();
  Future<void> setOnboardingCompleted();
}