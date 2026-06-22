// lib/core/error/exceptions.dart

/// Base for all data-layer exceptions (thrown, never returned).
abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);
  @override
  String toString() => '$runtimeType: $message';
}

// --- Network ---
class NetworkException extends AppException {
  const NetworkException(super.message);
}

class NetworkTimeoutException extends AppException {
  const NetworkTimeoutException(super.message);
}

// --- Auth ---
class AuthException extends AppException {
  const AuthException(super.message);
}

class AuthCancelledException extends AppException {
  const AuthCancelledException(super.message);
}

class AuthExpiredException extends AppException {
  const AuthExpiredException(super.message);
}

// --- Drive / remote ---
class StorageFullException extends AppException {
  const StorageFullException(super.message);
}

class RateLimitException extends AppException {
  const RateLimitException(super.message);
}

class DomainPolicyException extends AppException {
  const DomainPolicyException(super.message);
}

class ServerException extends AppException {
  const ServerException(super.message);
}

// --- Local ---
class CacheException extends AppException {
  const CacheException(super.message);
}

// --- Backup format ---
class BackupFormatException extends AppException {
  const BackupFormatException(super.message);
}