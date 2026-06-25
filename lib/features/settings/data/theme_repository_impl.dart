import 'package:routine/features/settings/domain/custom_theme_model.dart';
import 'package:routine/features/settings/domain/theme_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeRepositoryImpl implements ThemeRepository {
  static const String _themeIndexKey = 'selected_theme_index';
  static const String _customThemeKey = 'custom_theme_config';
  static const String _lastCustomThemeKey = 'last_custom_theme_config';

  // ── existing ──────────────────────────────────────────────────────────────

  @override
  Future<int> getSavedThemeIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_themeIndexKey) ?? 0;
  }

  @override
  Future<void> saveThemeIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeIndexKey, index);
  }

  // ── new ───────────────────────────────────────────────────────────────────

  @override
  Future<CustomThemeModel?> getSavedCustomTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_customThemeKey);
    if (json == null) return null;
    try {
      return CustomThemeModel.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveCustomTheme(CustomThemeModel model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customThemeKey, model.toJson());
  }
  Future<void> saveLastCustomTheme(CustomThemeModel model) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_lastCustomThemeKey, model.toJson());
}

Future<CustomThemeModel?> getLastCustomTheme() async {
  final prefs = await SharedPreferences.getInstance();
  final json = prefs.getString(_lastCustomThemeKey);
  if (json == null) return null;
  try { return CustomThemeModel.fromJson(json); } catch (_) { return null; }
}

}