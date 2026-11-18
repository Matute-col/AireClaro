import '../report/authorities_repository.dart';

/// GET /reports/:id/pqrsd → text of the request, its authority and the mail mode.
class PqrsdPreview {
  const PqrsdPreview({
    required this.authority,
    required this.plate,
    required this.status,
    required this.requesterEmail,
    required this.text,
    required this.mailMode,
  });

  final Authority authority;
  final String plate;
  final String status;

  /// Where the citizen receives the copy and the answer (US-21 dialog).
  final String requesterEmail;
  final String text;

  /// `test`, `live` or `off` (used by the email sending in US-21).
  final String mailMode;

  factory PqrsdPreview.fromJson(Map<String, dynamic> json) => PqrsdPreview(
        authority: Authority.fromJson(json['authority'] as Map<String, dynamic>),
        plate: json['plate'] as String,
        status: json['status'] as String,
        requesterEmail: json['requester_email'] as String? ?? '',
        text: json['text'] as String,
        mailMode: json['mail_mode'] as String? ?? 'test',
      );
}

/// First 8 characters of a report id, as in the PDF («Reporte n.º 3F2A9C1B»).
String shortReportId(String id) => id.replaceAll('-', '').substring(0, 8).toUpperCase();
