import '../entities/lock_type.dart';

abstract class AppLockRepository {
  /// Checks if biometric authentication is supported on the device.
  Future<bool> canAuthenticate();
Future<bool> isBiometricAvailable();
  /// Performs biometric authentication.
  /// Returns true if successful.
  Future<bool> authenticate({String reason = 'Authenticate to continue'});

  /// Returns the currently set lock type.
  Future<LockType> getLockType();

  /// Sets the lock type.
  Future<void> setLockType(LockType type);

  /// Saves a PIN (should be hashed in production).
  Future<void> savePin(String pin);

  /// Retrieves the saved PIN.
  Future<String?> getPin();

  /// Saves a security question and answer.
  Future<void> saveSecurityQuestion(String question, String answer);

  /// Retrieves the saved security data (question and answer).
  Future<Map<String, String>?> getSecurityData();

  /// Clears all lock-related data.
  Future<void> clearAll();
}