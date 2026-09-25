import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure({
    required this.title,
    required this.message,
    required this.statusCode,
  });

  final String message;
  final int statusCode;
  final String title;

  String get errorMessage => '$statusCode Error: $message';

  /// True only for the synthetic codes [NetworkUtils] assigns when the
  /// request never reached the server or got no response back (timeout,
  /// no internet, socket error) — as opposed to a real HTTP status the
  /// backend itself returned, which means the server was reached and is
  /// reporting a business-logic outcome (validation, no match, etc.).
  bool get isConnectivityFailure => statusCode == 408 || statusCode == 499;

  @override
  List<Object> get props => [message, statusCode, title];
}

class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    required super.statusCode,
    required super.title,
  });
}
