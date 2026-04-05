import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'package:bagyesrushappusernew/core/errors/failure.dart';
import 'app_logger.dart';

abstract class NetworkUtils {
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
        return Left(ServerFailure(
          message: e.message ?? 'An unexpected error occurred.',
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

      // Extract nested field-level errors (e.g. {"errors": {"phone": "..."}})
      final errors = data['errors'];
      String? errorDetail;
      if (errors is Map && errors.isNotEmpty) {
        errorDetail = errors.values
            .map((v) => v is List ? v.join(', ') : v.toString())
            .join('\n');
      }

      message = errorDetail ?? topMessage ?? message;
      appLogger.w('NetworkUtils.handleDioResponseError → $message');
    } else if (data is String && data.isNotEmpty) {
      message = data;
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

    return Left(ServerFailure(
      message: e.toString(),
      statusCode: 500,
      title: 'Unexpected Error',
    ));
  }
}
