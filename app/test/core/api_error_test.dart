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
  test('reads code, message and field errors from the API format', () {
    final error = toApiException(_withResponse(409, {
      'error': {
        'code': 'EMAIL_TAKEN',
        'message': 'Este correo ya está registrado.',
        'details': [
          {'field': 'email', 'message': 'Este correo ya está registrado.'},
        ],
      },
    }));

    expect(error.code, 'EMAIL_TAKEN');
    expect(error.statusCode, 409);
    expect(error.fieldErrors['email'], 'Este correo ya está registrado.');
  });

  test('connection problems become a network error in Spanish', () {
    final error = toApiException(DioException(
      requestOptions: RequestOptions(path: '/health'),
      type: DioExceptionType.connectionError,
    ));

    expect(error.isNetworkError, isTrue);
    expect(error.message, contains('No pudimos conectar'));
  });

  test('unexpected bodies give a generic message', () {
    final error = toApiException(_withResponse(500, '<html>'));

    expect(error.code, ApiException.unknownCode);
    expect(error.statusCode, 500);
  });
}
