import 'package:dio/dio.dart';

/// An error from the API (or the network) with a message ready to show in Spanish.
///
/// The API answers errors as `{ "error": { "code", "message", "details": [{field, message}] } }`.
class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.fieldErrors = const {},
  });

  static const networkCode = 'NETWORK_ERROR';
  static const unknownCode = 'UNKNOWN_ERROR';

  final String code;
  final String message;
  final int? statusCode;

  /// Error per form field, e.g. `{'email': 'Este correo ya está registrado.'}`.
  final Map<String, String> fieldErrors;

  bool get isNetworkError => code == networkCode;

  @override
  String toString() => 'ApiException($code, $statusCode)';
}

const _networkMessage =
    'No pudimos conectar con el servidor. Revisa tu conexión e inténtalo de nuevo.';
const _unknownMessage = 'Ocurrió un error inesperado. Inténtalo de nuevo.';

/// Converts any error from dio into an [ApiException].
ApiException toApiException(Object error) {
  if (error is ApiException) return error;
  if (error is! DioException) {
    return const ApiException(code: ApiException.unknownCode, message: _unknownMessage);
  }

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return const ApiException(code: ApiException.networkCode, message: _networkMessage);
    default:
      break;
  }

  final response = error.response;
  if (response == null) {
    return const ApiException(code: ApiException.networkCode, message: _networkMessage);
  }

  final data = response.data;
  final body = data is Map ? data['error'] : null;
  if (body is! Map) {
    return ApiException(
      code: ApiException.unknownCode,
      message: _unknownMessage,
      statusCode: response.statusCode,
    );
  }

  final fieldErrors = <String, String>{};
  final details = body['details'];
  if (details is List) {
    for (final item in details) {
      if (item is Map && item['field'] is String && item['message'] is String) {
        // Keep the first message per field.
        fieldErrors.putIfAbsent(item['field'] as String, () => item['message'] as String);
      }
    }
  }

  return ApiException(
    code: body['code'] is String ? body['code'] as String : ApiException.unknownCode,
    message: body['message'] is String ? body['message'] as String : _unknownMessage,
    statusCode: response.statusCode,
    fieldErrors: fieldErrors,
  );
}
