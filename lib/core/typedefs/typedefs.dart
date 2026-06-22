// lib/core/typedefs/typedefs.dart

import 'package:fpdart/fpdart.dart';

import '../error/failures.dart';

/// Future returning Either<Failure, T>.
typedef ResultFuture<T> = Future<Either<Failure, T>>;

/// Future returning Either<Failure, void>.
typedef ResultVoid = Future<Either<Failure, void>>;

/// Plain map alias for raw DB rows / JSON objects.
typedef DataMap = Map<String, Object?>;