import 'package:dartz/dartz.dart';
import '../core/errors/failures.dart';

typedef ResultFuture<T> = Future<Either<Failure, T>>;
typedef ResultStream<T> = Stream<Either<Failure, T>>;
typedef DataMap = Map<String, dynamic>;
typedef FutureVoid = Future<void>;
typedef FutureBool = Future<bool>;