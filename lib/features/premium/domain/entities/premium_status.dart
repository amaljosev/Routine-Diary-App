/// Represents whether the user has unlocked premium.
///
/// Keep this a plain Dart class — no Flutter, no packages.
/// Add future entitlements here (e.g. [aiSuggestions], [exportPdf]) as bools
/// so every feature can check a single object.
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