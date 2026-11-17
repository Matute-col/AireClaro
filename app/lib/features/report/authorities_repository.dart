import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/api_error.dart';

/// An authority that can receive the request (GET /authorities). Its email is never sent
/// to the app; [canEmail] only says whether it has a verified one.
class Authority {
  const Authority({
    required this.id,
    required this.code,
    required this.name,
    this.portalUrl,
    this.canEmail = false,
  });

  final int id;
  final String code;
  final String name;
  final String? portalUrl;
  final bool canEmail;

  factory Authority.fromJson(Map<String, dynamic> json) => Authority(
        id: json['id'] as int,
        code: json['code'] as String,
        name: json['name'] as String,
        portalUrl: json['portal_url'] as String?,
        canEmail: json['can_email'] as bool? ?? false,
      );
}

class AuthoritiesRepository {
  AuthoritiesRepository(this._dio);

  final Dio _dio;

  Future<List<Authority>> list() async {
    try {
      final response = await _dio.get<List<dynamic>>('/authorities');
      return response.data!.map((e) => Authority.fromJson(e as Map<String, dynamic>)).toList();
    } catch (error) {
      throw toApiException(error);
    }
  }
}

final authoritiesRepositoryProvider = Provider<AuthoritiesRepository>(
  (ref) => AuthoritiesRepository(ref.watch(apiClientProvider)),
);

/// The list rarely changes: loaded once and reused («Reintentar» invalidates it).
final authoritiesProvider = FutureProvider<List<Authority>>(
  (ref) => ref.watch(authoritiesRepositoryProvider).list(),
);
