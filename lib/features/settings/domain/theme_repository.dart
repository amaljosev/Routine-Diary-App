abstract class ThemeRepository {
  Future<int> getSavedThemeIndex();
  Future<void> saveThemeIndex(int index);
}