import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'package:gopady/core/errors/failure.dart';
import 'app_logger.dart';

abstract class NetworkUtils {
  // 499 keeps `Failure.isConnectivityFailure` true: the server was never
  // reached, so callers can offer a retry.
  static const _secureConnectionFailure = ServerFailure(
    message: 'Couldn\'t establish a secure connection. Please try again later.',
    statusCode: 499,
    title: 'Secure Connection Failed',
  );

  static Left<Failure, T> handleDioException<T>(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Left(const ServerFailure(
          message: 'Connection timed out. Please try again.',
          statusCode: 408,
          title: 'Timeout',
        ));
      case DioExceptionType.badCertificate:
        return Left(_secureConnectionFailure);
      case DioExceptionType.connectionError:
        return Left(const ServerFailure(
          message: 'No internet connection.',
          statusCode: 499,
          title: 'Connection Error',
        ));
      default:
        if (e.response != null) {
          return handleDioResponseError(e.response!);
        }
        // A failed TLS handshake surfaces as `unknown` with a null message.
        if (e.error is TlsException) {
          appLogger.w('NetworkUtils.handleDioException → TLS: ${e.error}');
          return Left(_secureConnectionFailure);
        }
        appLogger.w(
          'NetworkUtils.handleDioException → ${e.type}: ${e.message} ${e.error}',
        );
        return Left(const ServerFailure(
          message: 'An unexpected error occurred.',
          statusCode: 500,
          title: 'Error',
        ));
    }
  }

  static Left<Failure, T> handleDioResponseError<T>(Response response) {
    final data = response.data;
    String message = 'An error occurred.';
    String title = 'Error';

    if (data is Map<String, dynamic>) {
      final topMessage = data['message']?.toString() ?? data['error']?.toString();
      title = data['title']?.toString() ?? title;

      // Field-level errors ({"errors": {"code": ["Enter a promo code"]}}) —
      // show the first message, per the API's error envelope contract.
      final errors = data['errors'];
      String? errorDetail;
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        errorDetail = first is List
            ? (first.isEmpty ? null : first.first.toString())
            : first.toString();
      }

      message = errorDetail ?? topMessage ?? message;
      appLogger.w('NetworkUtils.handleDioResponseError → $message');
    } else if (data is String && data.isNotEmpty) {
      // Plain/HTML bodies (proxy or WAF error pages) are for the log only.
      final preview = data.length > 300 ? data.substring(0, 300) : data;
      appLogger.w(
        'NetworkUtils.handleDioResponseError → non-JSON body '
        '(${response.statusCode}): $preview',
      );
    }

    return Left(ServerFailure(
      message: message,
      statusCode: response.statusCode ?? 500,
      title: title,
    ));
  }

  static Left<Failure, T> handleException<T>(
    dynamic e,
    StackTrace s, {
    required String repositoryName,
    String? methodName,
  }) {
    appLogger.e(
      '$repositoryName${methodName != null ? '.$methodName' : ''}: $e',
      error: e,
      stackTrace: s,
    );

    if (e is SocketException) {
      return Left(const ServerFailure(
        message: 'No internet connection.',
        statusCode: 499,
        title: 'Network Error',
      ));
    }

    if (e is TlsException) return Left(_secureConnectionFailure);

    return Left(const ServerFailure(
      message: 'Something went wrong. Please try again.',
      statusCode: 500,
      title: 'Unexpected Error',
    ));
  }
}
