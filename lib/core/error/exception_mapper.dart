// lib/core/error/exception_mapper.dart

import 'package:fpdart/fpdart.dart';

import '../typedefs/typedefs.dart';
import 'exceptions.dart';
import 'failures.dart';

/// Maps a thrown exception to its user-facing Failure.
Failure mapExceptionToFailure(Object error) {
  if (error is NetworkException) return NetworkFailure(error.message);
  if (error is NetworkTimeoutException) return TimeoutFailure(error.message);
  if (error is AuthCancelledException) return AuthCancelledFailure(error.message);
  if (error is AuthExpiredException) return AuthExpiredFailure(error.message);
  if (error is AuthException) return AuthFailure(error.message);
  if (error is StorageFullException) return StorageFullFailure(error.message);
  if (error is RateLimitException) return RateLimitFailure(error.message);
  if (error is DomainPolicyException) return DomainPolicyFailure(error.message);
  if (error is ServerException) return ServerFailure(error.message);
  if (error is CacheException) return CacheFailure(error.message);
  if (error is BackupFormatException) return BackupFormatFailure(error.message);
  return UnknownFailure('$error');
}

/// Runs [action], returning Right on success or a mapped Left on throw.
/// This is how the repository keeps try/catch out of every method.
ResultFuture<T> guard<T>(Future<T> Function() action) async {
  try {
    final value = await action();
    return Right(value);
  } catch (e) {
    return Left(mapExceptionToFailure(e));
  }
}

/// Synchronous variant.
Either<Failure, T> guardSync<T>(T Function() action) {
  try {
    return Right(action());
  } catch (e) {
    return Left(mapExceptionToFailure(e));
  }
}