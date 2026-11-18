import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/api_error.dart';
import '../../core/validators.dart';
import '../history/report_detail.dart';
import '../history/report_summary.dart';
import '../pqrsd/pqrsd_preview.dart';
import '../../shared/services/file_actions.dart';
import 'report_draft.dart';

/// File parts of POST /reports, in order: the evidence in «files», then the frames of
/// each video in `frames_v<N>` (N = position of the video in «files», US-23). Only
/// frames that were extracted completely are sent; their order is their position.
List<(String field, String path)> evidenceParts(ReportDraft draft) {
  final parts = [for (final file in draft.evidence) ('files', file.path)];
  for (var i = 0; i < draft.evidence.length; i++) {
    final file = draft.evidence[i];
    if (file.isVideo && file.framesStatus == FramesStatus.ready) {
      parts.addAll(file.frames.map((frame) => ('frames_v$i', frame)));
    }
  }
  return parts;
}

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
  ReportsRepository(this._dio, this._tempPath);

  final Dio _dio;

  /// Where downloaded files are saved (the app's temporary folder).
  final Future<String> Function(String fileName) _tempPath;

  /// Creates the report with its evidence (multipart). Returns the new report id.
  /// [onProgress] receives 0.0–1.0 while the files are uploaded.
  Future<String> create(ReportDraft draft, {void Function(double progress)? onProgress}) async {
    try {
      final form = FormData.fromMap(reportFormFields(draft));
      for (final (field, path) in evidenceParts(draft)) {
        // The server ignores the file name and checks the real type itself.
        form.files.add(MapEntry(field, await MultipartFile.fromFile(path)));
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

  /// Text of the request for the preview (US-13).
  Future<PqrsdPreview> getPqrsd(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/reports/$id/pqrsd');
      return PqrsdPreview.fromJson(response.data!);
    } catch (error) {
      throw toApiException(error);
    }
  }

  /// Downloads the PDF of the request (with the session) and returns its local path.
  Future<String> downloadPdf(String id) async {
    final path = await _tempPath('solicitud-${shortReportId(id)}.pdf');
    await _download('/reports/$id/pqrsd.pdf', path);
    return path;
  }

  /// Downloads one evidence file (e.g. a video, CP-07) and returns its local path.
  Future<String> downloadMedia(String reportId, String mediaId, String extension) async {
    final path = await _tempPath('evidencia-${shortReportId(mediaId)}.$extension');
    await _download('/reports/$reportId/media/$mediaId', path);
    return path;
  }

  Future<void> _download(String url, String path) async {
    try {
      await _dio.download(
        url,
        path,
        options: Options(receiveTimeout: const Duration(minutes: 2)),
      );
    } catch (error) {
      throw toApiException(error);
    }
  }

  /// US-21 · Sends the request by email to the authority, after the user confirmed it.
  /// Errors keep the API message: 409 already sent, 422 no verified email, 502 SMTP
  /// failure, 503 email disabled or not configured.
  Future<SendResult> sendReport(String id) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/reports/$id/send',
        data: {'confirm': true},
        // Building the PDF and talking to the mail server can take a while.
        options: Options(receiveTimeout: const Duration(minutes: 1)),
      );
      return SendResult.fromJson(response.data!['delivery'] as Map<String, dynamic>);
    } catch (error) {
      throw toApiException(error);
    }
  }

  /// US-14 / US-22 · «Marcar como enviado» (presented through the portal or the shared PDF).
  Future<void> markAsSent(String id) async {
    try {
      await _dio.patch<Map<String, dynamic>>('/reports/$id/status', data: {'status': 'enviado'});
    } catch (error) {
      throw toApiException(error);
    }
  }

  /// US-18 · Deletes the report with its evidence (404 if it is not the user's).
  Future<void> deleteReport(String id) async {
    try {
      await _dio.delete<void>('/reports/$id');
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

/// Result of POST /reports/:id/send.
class SendResult {
  const SendResult({required this.mode, required this.evidenceAttached});

  /// `test` (went to the test inbox) or `live` (went to the authority).
  final String mode;
  final bool evidenceAttached;

  factory SendResult.fromJson(Map<String, dynamic> json) => SendResult(
        mode: json['mode'] as String,
        evidenceAttached: json['evidence_attached'] as bool? ?? false,
      );
}

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepository(
    ref.watch(apiClientProvider),
    ref.watch(fileActionsProvider).tempPath,
  ),
);
