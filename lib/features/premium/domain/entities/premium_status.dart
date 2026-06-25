// lib/features/premium/domain/entities/premium_status.dart
class PremiumStatus {
  final bool isPremium;

  // Add future entitlement flags here, e.g.:
  // final bool aiSuggestionsUnlocked;
  // final bool exportPdfUnlocked;

  const PremiumStatus({required this.isPremium});

  const PremiumStatus.free() : isPremium = false;
  const PremiumStatus.premium() : isPremium = true;

  @override
  bool operator ==(Object other) =>
      other is PremiumStatus && other.isPremium == isPremium;

  @override
  int get hashCode => isPremium.hashCode;
}