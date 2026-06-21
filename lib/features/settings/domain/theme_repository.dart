import 'custom_theme_model.dart';

abstract class ThemeRepository {
  Future<int> getSavedThemeIndex();
  Future<void> saveThemeIndex(int index);
  Future<CustomThemeModel?> getSavedCustomTheme();
  Future<void> saveCustomTheme(CustomThemeModel model);
}
