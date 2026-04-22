// lib/core/services/showcase_prefs_service.dart

import 'package:shared_preferences/shared_preferences.dart';

class ShowcasePrefsService {
  ShowcasePrefsService._internal(this._prefs);

  static ShowcasePrefsService? _instance;

  /// Call once in main() before runApp().
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _instance = ShowcasePrefsService._internal(prefs);
  }

  static ShowcasePrefsService get instance {
    assert(
      _instance != null,
      'Call ShowcasePrefsService.init() before accessing instance.',
    );
    return _instance!;
  }

  final SharedPreferences _prefs;

  // ── Keys ───────────────────────────────────────────────────────────────────
  static const _kHomeKey  = 'diary_showcase_seen';        // home nav bar
  static const _kEntryKey = 'diary_entry_showcase_seen';  // entry toolbar

  // ── Home screen ────────────────────────────────────────────────────────────
  bool get hasSeenHomeShowcase  => _prefs.getBool(_kHomeKey)  ?? false;
  Future<void> markHomeShowcaseSeen()  => _prefs.setBool(_kHomeKey,  true);

  // ── Entry screen ───────────────────────────────────────────────────────────
  bool get hasSeenEntryShowcase => _prefs.getBool(_kEntryKey) ?? false;
  Future<void> markEntryShowcaseSeen() => _prefs.setBool(_kEntryKey, true);
}