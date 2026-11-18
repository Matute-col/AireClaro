import 'package:aireclaro/core/api_error.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _withResponse(int status, Object? data) {
  final options = RequestOptions(path: '/auth/register');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: options, statusCode: status, data: data),
  );
}

void main() {
  _registerStateTests();

  test('reads code, message and field errors from the API format', () {
    final error = toApiException(
      _withResponse(409, {
        'error': {
          'code': 'EMAIL_TAKEN',
          'message': 'Este correo ya está registrado.',
          'details': [
            {'field': 'email', 'message': 'Este correo ya está registrado.'},
          ],
        },
      }),
    );

    expect(error.code, 'EMAIL_TAKEN');
    expect(error.statusCode, 409);
    expect(error.fieldErrors['email'], 'Este correo ya está registrado.');
  });

  test('connection problems become a network error in Spanish', () {
    final error = toApiException(
      DioException(
        requestOptions: RequestOptions(path: '/health'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(error.isNetworkError, isTrue);
    expect(error.message, contains('No pudimos conectar'));
  });

  test('unexpected bodies give a generic message', () {
    final error = toApiException(_withResponse(500, '<html>'));

    expect(error.code, ApiException.unknownCode);
    expect(error.statusCode, 500);
  });
}

// US-17 · Every error the user can meet ends in a clear message in Spanish.

final _cases = <String, (DioException, String, int?)>{
  'too many requests (429) keeps the API message': (
    DioException(
      requestOptions: RequestOptions(path: '/reports'),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: '/reports'),
        statusCode: 429,
        data: {
          'error': {
            'code': 'TOO_MANY_REQUESTS',
            'message': 'Demasiadas peticiones. Espera unos minutos e intenta de nuevo.',
          },
        },
      ),
    ),
    'Demasiadas peticiones. Espera unos minutos e intenta de nuevo.',
    429,
  ),
  'server error (500) keeps the generic API message': (
    DioException(
      requestOptions: RequestOptions(path: '/reports'),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: '/reports'),
        statusCode: 500,
        data: {
          'error': {
            'code': 'INTERNAL_ERROR',
            'message': 'Ocurrió un error inesperado. Intenta de nuevo.',
          },
        },
      ),
    ),
    'Ocurrió un error inesperado. Intenta de nuevo.',
    500,
  ),
  'slow server (timeout) is treated as no connection': (
    DioException(
      requestOptions: RequestOptions(path: '/reports'),
      type: DioExceptionType.receiveTimeout,
    ),
    'No pudimos conectar con el servidor. Revisa tu conexión e inténtalo de nuevo.',
    null,
  ),
  'a cancelled or unknown failure never shows technical text': (
    DioException(
      requestOptions: RequestOptions(path: '/reports'),
      type: DioExceptionType.unknown,
    ),
    'No pudimos conectar con el servidor. Revisa tu conexión e inténtalo de nuevo.',
    null,
  ),
};

void _registerStateTests() {
  group('US-17 · error messages', () {
    for (final MapEntry(key: name, value: (error, message, status))
        in _cases.entries) {
      test(name, () {
        final result = toApiException(error);
        expect(result.message, message);
        expect(result.statusCode, status);
      });
    }

    test('anything that is not an HTTP error gets the generic message', () {
      expect(
        toApiException(StateError('x')).message,
        'Ocurrió un error inesperado. Inténtalo de nuevo.',
      );
    });
  });
}
