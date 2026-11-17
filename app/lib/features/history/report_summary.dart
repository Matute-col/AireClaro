/// One row of «Mis reportes» (GET /reports items).
class ReportSummary {
  const ReportSummary({
    required this.id,
    required this.plate,
    required this.vehicleType,
    required this.status,
    required this.occurredAt,
    this.address,
    this.authorityName,
    this.thumbnailMediaId,
    this.mediaCount = 0,
  });

  final String id;
  final String plate;
  final String vehicleType;
  final String status;
  final DateTime occurredAt;
  final String? address;
  final String? authorityName;

  /// A photo to show as thumbnail; null if the report only has videos.
  final String? thumbnailMediaId;
  final int mediaCount;

  factory ReportSummary.fromJson(Map<String, dynamic> json) => ReportSummary(
        id: json['id'] as String,
        plate: json['plate'] as String,
        vehicleType: json['vehicle_type'] as String,
        status: json['status'] as String,
        occurredAt: DateTime.parse(json['occurred_at'] as String).toLocal(),
        address: json['address'] as String?,
        authorityName: (json['authority'] as Map<String, dynamic>?)?['name'] as String?,
        thumbnailMediaId: json['thumbnail_media_id'] as String?,
        mediaCount: json['media_count'] as int? ?? 0,
      );
}

/// One page of GET /reports.
class ReportsPage {
  const ReportsPage({required this.items, required this.page, required this.total});

  final List<ReportSummary> items;
  final int page;
  final int total;

  factory ReportsPage.fromJson(Map<String, dynamic> json) => ReportsPage(
        items: (json['items'] as List<dynamic>)
            .map((e) => ReportSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
        page: json['page'] as int,
        total: json['total'] as int,
      );
}
