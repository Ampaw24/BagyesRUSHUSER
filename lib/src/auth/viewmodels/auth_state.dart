import 'package:equatable/equatable.dart';

import 'package:bagyesrushappusernew/core/errors/failure.dart';

sealed class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object> get props => [];
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class RequestingOTP extends AuthLoading {
  const RequestingOTP();
}

final class LoggedIn extends AuthState {
  const LoggedIn();
}

final class Registered extends AuthState {
  const Registered();
}

final class VendorRegistered extends AuthState {
  const VendorRegistered();
}

final class OTPSent extends AuthState {
  const OTPSent();
}

final class OTPVerified extends AuthState {
  const OTPVerified();
}

final class LoggedOut extends AuthState {
  const LoggedOut();
}

final class TokenRefreshed extends AuthState {
  const TokenRefreshed();
}

final class AuthError extends AuthState {
  const AuthError({required this.message, required this.title});

  AuthError.fromFailure(Failure failure)
      : this(message: failure.message, title: failure.title);

  final String message;
  final String title;

  @override
  List<Object> get props => [message, title];
}

final class NetworkError extends AuthError {
  const NetworkError({required super.message, required super.title});

  NetworkError.fromFailure(Failure failure)
      : super(message: failure.message, title: failure.title);
}
