import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/api_error.dart';
import 'user.dart';

/// Data for POST /auth/register.
class RegisterData {
  const RegisterData({
    required this.fullName,
    required this.docType,
    required this.docNumber,
    required this.email,
    required this.password,
    this.phone,
  });

  final String fullName;
  final String docType;
  final String docNumber;
  final String email;
  final String password;
  final String? phone;

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'doc_type': docType,
        'doc_number': docNumber,
        'email': email,
        'phone': phone,
        'password': password,
        'accept_terms': true,
      };
}

/// Token plus user, returned by register and login.
class AuthResult {
  const AuthResult({required this.token, required this.user});

  final String token;
  final User user;

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        token: json['token'] as String,
        user: User.fromJson(json['user'] as Map<String, dynamic>),
      );
}

/// Calls to the auth endpoints. Every error is turned into an [ApiException].
class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  Future<AuthResult> register(RegisterData data) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: data.toJson(),
      );
      return AuthResult.fromJson(response.data!);
    } catch (error) {
      throw toApiException(error);
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);
