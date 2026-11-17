import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/api_error.dart';
import '../auth/user.dart';

/// Editable profile fields (PUT /me). The email cannot be changed (RF-13).
class ProfileData {
  const ProfileData({
    required this.fullName,
    required this.docType,
    required this.docNumber,
    this.phone,
  });

  final String fullName;
  final String docType;
  final String docNumber;
  final String? phone;

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'doc_type': docType,
        'doc_number': docNumber,
        'phone': phone,
      };
}

class ProfileRepository {
  ProfileRepository(this._dio);

  final Dio _dio;

  Future<User> update(ProfileData data) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>('/me', data: data.toJson());
      return User.fromJson(response.data!['user'] as Map<String, dynamic>);
    } catch (error) {
      throw toApiException(error);
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(apiClientProvider)),
);
