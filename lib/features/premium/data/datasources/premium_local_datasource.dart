// lib/features/premium/data/datasources/premium_local_datasource.dart
import 'package:shared_preferences/shared_preferences.dart';

/// All SharedPreferences keys live in one place.
abstract final class PreferenceKeys {
  static const String kPremiumUnlocked = 'premium_unlocked';

  /// Set to true the first time a user subscribes. Never cleared.
  /// Allows us to distinguish "never subscribed" from "lapsed subscriber".
  static const String kWasEverSubscriber = 'was_ever_subscriber';
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
    // Also stamp the "was ever a subscriber" flag — never cleared afterwards.
    await prefs.setBool(PreferenceKeys.kWasEverSubscriber, true);
  }

  /// Removes the locally cached premium flag.
  /// Called when the store confirms the subscription has expired.
  /// kWasEverSubscriber is intentionally NOT cleared here.
  Future<void> clearPremiumUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(PreferenceKeys.kPremiumUnlocked);
    // kWasEverSubscriber is deliberately left intact.
  }

  /// Returns true if the user has ever been a subscriber, regardless of
  /// current subscription status.
  ///
  /// State matrix:
  ///   kPremiumUnlocked=false, kWasEverSubscriber=false → Never subscribed
  ///   kPremiumUnlocked=false, kWasEverSubscriber=true  → Lapsed subscriber
  ///   kPremiumUnlocked=true,  kWasEverSubscriber=true  → Active subscriber
  Future<bool> wasEverSubscriber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PreferenceKeys.kWasEverSubscriber) ?? false;
  }
}