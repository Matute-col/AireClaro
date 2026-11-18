import '../report/authorities_repository.dart';
import '../report/report_draft.dart';

/// One evidence file of a saved report (the file itself is read with the token).
class ReportMedia {
  const ReportMedia({
    required this.id,
    required this.kind,
    required this.sizeBytes,
    this.mimeType = '',
    this.frames = const [],
  });

  final String id;
  final EvidenceKind kind;
  final int sizeBytes;
  final String mimeType;

  /// US-23 · Frames extracted from this video, in order (position 1..4).
  final List<ReportFrame> frames;

  bool get isVideo => kind == EvidenceKind.video;

  /// File extension for the downloaded copy.
  String get extension => switch (mimeType) {
        'video/quicktime' => 'mov',
        'video/mp4' => 'mp4',
        'image/png' => 'png',
        'image/webp' => 'webp',
        _ => isVideo ? 'mp4' : 'jpg',
      };

  factory ReportMedia.fromJson(Map<String, dynamic> json) => ReportMedia(
        id: json['id'] as String,
        kind: json['kind'] == 'video' ? EvidenceKind.video : EvidenceKind.photo,
        sizeBytes: json['size_bytes'] as int,
        mimeType: json['mime_type'] as String? ?? '',
        frames: ((json['frames'] as List<dynamic>?) ?? const [])
            .map((f) => ReportFrame.fromJson(f as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.position.compareTo(b.position)),
      );
}

/// US-23 · One frame of a video (derived evidence, read with the session like any file).
class ReportFrame {
  const ReportFrame({required this.id, required this.position});

  final String id;
  final int position;

  factory ReportFrame.fromJson(Map<String, dynamic> json) =>
      ReportFrame(id: json['id'] as String, position: json['position'] as int);
}

/// GET /reports/:id → {report, media, authority}.
class ReportDetail {
  const ReportDetail({
    required this.id,
    required this.vehicleType,
    required this.plate,
    required this.smokeColor,
    required this.lat,
    required this.lng,
    required this.occurredAt,
    required this.status,
    required this.requesterName,
    required this.requesterDocType,
    required this.requesterDocNumber,
    required this.requesterEmail,
    required this.media,
    required this.authority,
    this.description,
    this.address,
    this.requesterPhone,
    this.sentAt,
    this.sentVia,
    this.sendMode,
  });

  final String id;
  final String vehicleType;
  final String plate;
  final String smokeColor;
  final String? description;
  final double lat;
  final double lng;
  final String? address;
  final DateTime occurredAt;
  final String status;
  final DateTime? sentAt;

  /// `email` or `manual` once sent; `test` or `live` when sent by email.
  final String? sentVia;
  final String? sendMode;
  final String requesterName;
  final String requesterDocType;
  final String requesterDocNumber;
  final String requesterEmail;
  final String? requesterPhone;
  final List<ReportMedia> media;
  final Authority authority;

  factory ReportDetail.fromJson(Map<String, dynamic> json) {
    final r = json['report'] as Map<String, dynamic>;
    final sentAt = r['sent_at'] as String?;
    return ReportDetail(
      id: r['id'] as String,
      vehicleType: r['vehicle_type'] as String,
      plate: r['plate'] as String,
      smokeColor: r['smoke_color'] as String,
      description: r['description'] as String?,
      lat: (r['lat'] as num).toDouble(),
      lng: (r['lng'] as num).toDouble(),
      address: r['address'] as String?,
      occurredAt: DateTime.parse(r['occurred_at'] as String).toLocal(),
      status: r['status'] as String,
      sentVia: r['sent_via'] as String?,
      sendMode: r['send_mode'] as String?,
      sentAt: sentAt == null ? null : DateTime.parse(sentAt).toLocal(),
      requesterName: r['requester_name'] as String,
      requesterDocType: r['requester_doc_type'] as String,
      requesterDocNumber: r['requester_doc_number'] as String,
      requesterEmail: r['requester_email'] as String,
      requesterPhone: r['requester_phone'] as String?,
      media: (json['media'] as List<dynamic>)
          .map((m) => ReportMedia.fromJson(m as Map<String, dynamic>))
          .toList(),
      authority: Authority.fromJson(json['authority'] as Map<String, dynamic>),
    );
  }
}
