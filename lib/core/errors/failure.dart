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
