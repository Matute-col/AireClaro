import 'dart:convert';
import 'dart:typed_data';

import 'package:aireclaro/core/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

/// Answers every request with [status] and remembers the last request.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.status);

  final int status;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      jsonEncode({'error': {'code': 'UNAUTHORIZED', 'message': 'x'}}),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  Future<(int, _FakeAdapter)> call({String? token, int status = 401}) async {
    var unauthorizedCalls = 0;
    final dio = createApiClient(
      baseUrl: 'http://api.test',
      tokenStorage: MemoryTokenStorage(token),
      onUnauthorized: () => unauthorizedCalls++,
    );
    final adapter = _FakeAdapter(status);
    dio.httpClientAdapter = adapter;
    try {
      await dio.get<dynamic>('/me');
    } on DioException {
      // Expected for error statuses.
    }
    return (unauthorizedCalls, adapter);
  }

  test('adds the Bearer token when there is a session', () async {
    final (_, adapter) = await call(token: 'abc', status: 200);
    expect(adapter.lastRequest?.headers['Authorization'], 'Bearer abc');
  });

  test('401 with a token closes the session', () async {
    final (calls, _) = await call(token: 'abc');
    expect(calls, 1);
  });

  test('401 without a token (wrong login) does not', () async {
    final (calls, adapter) = await call();
    expect(calls, 0);
    expect(adapter.lastRequest?.headers.containsKey('Authorization'), isFalse);
  });
}
