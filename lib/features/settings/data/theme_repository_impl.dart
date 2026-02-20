import 'package:routine/features/settings/domain/theme_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeRepositoryImpl implements ThemeRepository {
  static const String _key = 'selected_theme_index';

  @override
  Future<int> getSavedThemeIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key) ?? 0; 
  }

  @override
  Future<void> saveThemeIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, index);
  }
}