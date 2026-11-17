import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/api_error.dart';

/// Answer of GET /geo/reverse. Any field can be null (e.g. a point without address).
class GeoResult {
  const GeoResult({this.address, this.municipality, this.suggestedAuthorityId});

  final String? address;
  final String? municipality;
  final int? suggestedAuthorityId;

  factory GeoResult.fromJson(Map<String, dynamic> json) => GeoResult(
        address: json['address'] as String?,
        municipality: json['municipality'] as String?,
        suggestedAuthorityId: json['suggested_authority_id'] as int?,
      );
}

/// Address and suggested authority for a point. Always through our API
/// (it applies Nominatim's rules: 1 request/s and cache), never Nominatim directly.
class GeoRepository {
  GeoRepository(this._dio);

  final Dio _dio;

  Future<GeoResult> reverse(double lat, double lng) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/geo/reverse',
        queryParameters: {'lat': lat, 'lng': lng},
      );
      return GeoResult.fromJson(response.data!);
    } catch (error) {
      throw toApiException(error);
    }
  }
}

final geoRepositoryProvider = Provider<GeoRepository>(
  (ref) => GeoRepository(ref.watch(apiClientProvider)),
);
