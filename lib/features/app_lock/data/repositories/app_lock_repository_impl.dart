import '../../domain/entities/lock_type.dart';
import '../../domain/repositories/app_lock_repository.dart';
import '../datasources/biometric_local_auth_datasource.dart';
import '../datasources/shared_preferences_datasource.dart';

class AppLockRepositoryImpl implements AppLockRepository {
  final BiometricLocalAuthDataSource biometricDataSource;
  final SharedPreferencesDataSource prefsDataSource;

  AppLockRepositoryImpl({
    required this.biometricDataSource,
    required this.prefsDataSource,
  });

  @override
  Future<bool> canAuthenticate() => biometricDataSource.canAuthenticate();
@override
Future<bool> isBiometricAvailable() async {
  try {
    final canAuth = await biometricDataSource.canAuthenticate();
    return canAuth;
  } catch (_) {
    return false;
  }
}
  @override
  Future<bool> authenticate({String reason = 'Authenticate to continue'}) =>
      biometricDataSource.authenticate(reason: reason);

  @override
  Future<LockType> getLockType() async {
    final value = await prefsDataSource.getString(SharedPreferencesDataSource.lockTypeKey);
    return LockType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LockType.none,
    );
  }

  @override
  Future<void> setLockType(LockType type) async {
    await prefsDataSource.setString(SharedPreferencesDataSource.lockTypeKey, type.name);
  }

  @override
  Future<void> savePin(String pin) async {
    await prefsDataSource.setString(SharedPreferencesDataSource.pinKey, pin);
  }

  @override
  Future<String?> getPin() async {
    return prefsDataSource.getString(SharedPreferencesDataSource.pinKey);
  }

  @override
  Future<void> saveSecurityQuestion(String question, String answer) async {
    await prefsDataSource.setString(SharedPreferencesDataSource.questionKey, question);
    await prefsDataSource.setString(SharedPreferencesDataSource.answerKey, answer);
  }

  @override
  Future<Map<String, String>?> getSecurityData() async {
    final q = await prefsDataSource.getString(SharedPreferencesDataSource.questionKey);
    final a = await prefsDataSource.getString(SharedPreferencesDataSource.answerKey);
    if (q == null || a == null) return null;
    return {'question': q, 'answer': a};
  }

  @override
  Future<void> clearAll() async {
    await prefsDataSource.clear();
  }
}