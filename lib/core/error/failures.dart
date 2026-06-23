// lib/core/error/failures.dart

import 'package:equatable/equatable.dart';

/// Sealed base Failure — returned via Either, equatable for tests.
sealed class Failure extends Equatable {
  /// User-facing message (safe to show in UI).
  final String message;
  const Failure(this.message);

  /// Whether the operation is worth retrying automatically.
  bool get isRetryable => false;

  @override
  List<Object?> get props => [message, isRetryable];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);
  @override
  bool get isRetryable => true;
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'The request timed out.']);
  @override
  bool get isRetryable => true;
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed.']);
}


class AuthCancelledFailure extends Failure {
  const AuthCancelledFailure([super.message = 'Sign-in was cancelled.']);
}

class AuthExpiredFailure extends Failure {
  const AuthExpiredFailure(
      [super.message = 'Your session expired. Please sign in again.']);
}

class StorageFullFailure extends Failure {
  const StorageFullFailure(
      [super.message = 'Google Drive is full. Free up space and try again.']);
}

class RateLimitFailure extends Failure {
  const RateLimitFailure([super.message = 'Too many requests. Try again shortly.']);
  @override
  bool get isRetryable => true;
}

class DomainPolicyFailure extends Failure {
  const DomainPolicyFailure(
      [super.message = 'Your organization has blocked Drive access.']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Something went wrong on the server.']);
  @override
  bool get isRetryable => true;
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Failed to read local data.']);
}

class BackupFormatFailure extends Failure {
  const BackupFormatFailure(
      [super.message = 'This backup is corrupt or unsupported.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred.']);
}