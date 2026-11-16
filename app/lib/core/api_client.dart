import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config.dart';
import 'token_storage.dart';

/// Creates the HTTP client used for every call to the AireClaro API.
///
/// - Adds `Authorization: Bearer <token>` when there is a session.
/// - If an authenticated request gets 401 (expired or invalid token), calls
///   [onUnauthorized] so the app can close the session and go to the login.
///   Requests without a token (login, register) are not affected.
Dio createApiClient({
  required String baseUrl,
  required TokenStorage tokenStorage,
  required void Function() onUnauthorized,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStorage.read();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        final hadToken = error.requestOptions.headers.containsKey('Authorization');
        if (error.response?.statusCode == 401 && hadToken) {
          onUnauthorized();
        }
        handler.next(error);
      },
    ),
  );

  return dio;
}

/// App-wide HTTP client. Session expiry handling is connected in the auth feature.
final apiClientProvider = Provider<Dio>((ref) {
  return createApiClient(
    baseUrl: AppConfig.apiBaseUrl,
    tokenStorage: ref.watch(tokenStorageProvider),
    onUnauthorized: () {},
  );
});
