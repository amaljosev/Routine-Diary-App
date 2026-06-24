import 'package:shared_preferences/shared_preferences.dart';

/// All SharedPreferences keys live in one place.
/// Add future feature keys here (e.g. kAiSuggestionsKey).
abstract final class PreferenceKeys {
  static const String kPremiumUnlocked = 'premium_unlocked';
}

/// Reads and writes premium status to local storage.
/// No business logic here — only raw persistence.
class PremiumLocalDataSource {
  Future<bool> isPremiumUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PreferenceKeys.kPremiumUnlocked) ?? false;
  }

  Future<void> setPremiumUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PreferenceKeys.kPremiumUnlocked, true);
  }
}