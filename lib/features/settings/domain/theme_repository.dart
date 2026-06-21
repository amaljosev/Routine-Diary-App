import 'custom_theme_model.dart';

abstract class ThemeRepository {
  // ── existing ──────────────────────────────────────────────────────────────
  Future<int> getSavedThemeIndex();
  Future<void> saveThemeIndex(int index);

  // ── new: custom theme persistence ─────────────────────────────────────────

  /// Returns the saved [CustomThemeModel] or null if none has been saved yet.
  Future<CustomThemeModel?> getSavedCustomTheme();

  /// Persists [model] locally (SharedPreferences JSON).
  Future<void> saveCustomTheme(CustomThemeModel model);
}