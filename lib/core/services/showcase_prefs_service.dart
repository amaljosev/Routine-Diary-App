// lib/core/services/showcase_prefs_service.dart
//
// No DI framework needed. Call ShowcasePrefsService.instance after init().

import 'package:shared_preferences/shared_preferences.dart';

class ShowcasePrefsService {
  ShowcasePrefsService._internal(this._prefs);

  static ShowcasePrefsService? _instance;

  // Call once in main() before runApp — after SharedPreferences.getInstance().
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _instance = ShowcasePrefsService._internal(prefs);
  }

  static ShowcasePrefsService get instance {
    assert(
      _instance != null,
      'ShowcasePrefsService.init() must be called before accessing instance.',
    );
    return _instance!;
  }

  final SharedPreferences _prefs;

  static const _kKey = 'diary_showcase_seen';

  bool get hasSeenShowcase => _prefs.getBool(_kKey) ?? false;

  Future<void> markShowcaseSeen() => _prefs.setBool(_kKey, true);
}