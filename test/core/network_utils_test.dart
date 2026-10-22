import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gopady/core/errors/failure.dart';
import 'package:gopady/core/utils/network_utils.dart';

Failure _failure(Either<Failure, void> result) =>
    result.fold((failure) => failure, (_) => fail('expected a failure'));

DioException _dioException(
  DioExceptionType type, {
  Object? error,
  Response<dynamic>? response,
}) => DioException(
  requestOptions: RequestOptions(path: '/login'),
  type: type,
  error: error,
  response: response,
);

Response<dynamic> _response(int status, Object? data) => Response<dynamic>(
  requestOptions: RequestOptions(path: '/login'),
  statusCode: status,
  data: data,
);

void main() {
  group('handleDioException', () {
    test('failed TLS handshake (type unknown) is a secure-connection failure',
        () {
      final failure = _failure(
        NetworkUtils.handleDioException<void>(
          _dioException(
            DioExceptionType.unknown,
            error: const HandshakeException('unrecognized name'),
          ),
        ),
      );

      expect(failure.title, 'Secure Connection Failed');
      expect(failure.message, isNot(contains('unrecognized name')));
      expect(failure.isConnectivityFailure, isTrue);
    });

    test('bad certificate is a secure-connection failure', () {
      final failure = _failure(
        NetworkUtils.handleDioException<void>(
          _dioException(DioExceptionType.badCertificate),
        ),
      );

      expect(failure.title, 'Secure Connection Failed');
      expect(failure.isConnectivityFailure, isTrue);
    });

    test('connection error still reads as no internet', () {
      final failure = _failure(
        NetworkUtils.handleDioException<void>(
          _dioException(DioExceptionType.connectionError),
        ),
      );

      expect(failure.message, 'No internet connection.');
      expect(failure.isConnectivityFailure, isTrue);
    });

    test('unknown error never surfaces the raw exception text', () {
      final failure = _failure(
        NetworkUtils.handleDioException<void>(
          _dioException(
            DioExceptionType.unknown,
            error: StateError('boom internals'),
          ),
        ),
      );

      expect(failure.message, 'An unexpected error occurred.');
      expect(failure.isConnectivityFailure, isFalse);
    });

    test('an error carrying a response defers to the response handler', () {
      final failure = _failure(
        NetworkUtils.handleDioException<void>(
          _dioException(
            DioExceptionType.badResponse,
            response: _response(422, {'message': 'Invalid credentials'}),
          ),
        ),
      );

      expect(failure.message, 'Invalid credentials');
      expect(failure.statusCode, 422);
    });
  });

  group('handleDioResponseError', () {
    test('HTML error pages are not shown to the user', () {
      final failure = _failure(
        NetworkUtils.handleDioResponseError<void>(
          _response(502, '<html><body>502 Bad Gateway</body></html>'),
        ),
      );

      expect(failure.message, 'An error occurred.');
      expect(failure.statusCode, 502);
    });

    test('field-level errors win over the top-level message', () {
      final failure = _failure(
        NetworkUtils.handleDioResponseError<void>(
          _response(422, {
            'message': 'The given data was invalid.',
            'errors': {
              'phone': ['The phone has already been taken.'],
            },
          }),
        ),
      );

      expect(failure.message, 'The phone has already been taken.');
    });
  });

  group('handleException', () {
    test('socket errors read as no internet', () {
      final failure = _failure(
        NetworkUtils.handleException<void>(
          const SocketException('Failed host lookup'),
          StackTrace.empty,
          repositoryName: 'TestRepository',
        ),
      );

      expect(failure.isConnectivityFailure, isTrue);
    });

    test('TLS errors are a secure-connection failure', () {
      final failure = _failure(
        NetworkUtils.handleException<void>(
          const HandshakeException('unrecognized name'),
          StackTrace.empty,
          repositoryName: 'TestRepository',
        ),
      );

      expect(failure.title, 'Secure Connection Failed');
    });

    test('unexpected exceptions never surface their toString()', () {
      final failure = _failure(
        NetworkUtils.handleException<void>(
          const FormatException("type 'String' is not a subtype of 'Map'"),
          StackTrace.empty,
          repositoryName: 'TestRepository',
        ),
      );

      expect(failure.message, 'Something went wrong. Please try again.');
      expect(failure.statusCode, 500);
    });
  });
}
