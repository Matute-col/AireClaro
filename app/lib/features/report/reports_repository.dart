import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/api_error.dart';
import '../../core/validators.dart';
import '../history/report_detail.dart';
import '../history/report_summary.dart';
import 'report_draft.dart';

/// Text fields of POST /reports built from the draft (docs/05).
Map<String, String> reportFormFields(ReportDraft draft) {
  final r = draft.requester;
  return {
    'vehicle_type': draft.vehicleType ?? '',
    'plate': Validators.normalizePlate(draft.plate),
    'smoke_color': draft.smokeColor ?? '',
    'description': draft.description.trim(),
    'lat': draft.lat.toString(),
    'lng': draft.lng.toString(),
    'address': draft.address ?? '',
    'occurred_at': draft.occurredAt!.toUtc().toIso8601String(),
    'authority_id': draft.authorityId?.toString() ?? '',
    'requester_name': r.name.trim(),
    'requester_doc_type': r.docType ?? '',
    'requester_doc_number': r.docNumber.trim().toUpperCase(),
    'requester_email': r.email.trim().toLowerCase(),
    'requester_phone': Validators.cleanPhone(r.phone),
  };
}

class ReportsRepository {
  ReportsRepository(this._dio);

  final Dio _dio;

  /// Creates the report with its evidence (multipart). Returns the new report id.
  /// [onProgress] receives 0.0–1.0 while the files are uploaded.
  Future<String> create(ReportDraft draft, {void Function(double progress)? onProgress}) async {
    try {
      final form = FormData.fromMap(reportFormFields(draft));
      for (final file in draft.evidence) {
        // The server ignores the file name and checks the real type itself.
        form.files.add(MapEntry('files', await MultipartFile.fromFile(file.path)));
      }
      final response = await _dio.post<Map<String, dynamic>>(
        '/reports',
        data: form,
        options: Options(
          // Up to 3 files of 25 MB on a mobile connection.
          sendTimeout: const Duration(minutes: 3),
          receiveTimeout: const Duration(minutes: 1),
        ),
        onSendProgress: (sent, total) {
          if (total > 0) onProgress?.call(sent / total);
        },
      );
      return (response.data!['report'] as Map<String, dynamic>)['id'] as String;
    } catch (error) {
      throw toApiException(error);
    }
  }

  /// Report detail (only the owner's reports; otherwise the API answers 404).
  Future<ReportDetail> getById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/reports/$id');
      return ReportDetail.fromJson(response.data!);
    } catch (error) {
      throw toApiException(error);
    }
  }

  /// «Mis reportes»: newest first, [limit] per page.
  Future<ReportsPage> list({int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/reports',
        queryParameters: {'page': page, 'limit': limit},
      );
      return ReportsPage.fromJson(response.data!);
    } catch (error) {
      throw toApiException(error);
    }
  }
}

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepository(ref.watch(apiClientProvider)),
);
