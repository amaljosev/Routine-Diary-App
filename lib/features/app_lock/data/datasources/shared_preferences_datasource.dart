import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesDataSource {
  static const String lockTypeKey = 'app_lock_type';
  static const String pinKey = 'app_lock_pin';
  static const String questionKey = 'app_lock_question';
  static const String answerKey = 'app_lock_answer';

  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}