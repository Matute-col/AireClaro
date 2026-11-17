import 'package:flutter_riverpod/flutter_riverpod.dart';

enum EvidenceKind { photo, video }

/// A photo or video chosen for the report (still only on the phone).
class EvidenceFile {
  const EvidenceFile({required this.path, required this.kind, required this.sizeBytes});

  final String path;
  final EvidenceKind kind;
  final int sizeBytes;

  bool get isVideo => kind == EvidenceKind.video;
}

/// Limits from docs/05 (the API checks them again).
class EvidenceLimits {
  EvidenceLimits._();

  static const maxFiles = 3;
  static const maxPhotoBytes = 8 * 1024 * 1024;
  static const maxVideoBytes = 25 * 1024 * 1024;
  static const maxVideoSeconds = 15;
}

/// The report being created, kept in memory during steps 1–4 (docs/06).
/// There are no drafts: it is lost when the user leaves the flow.
class ReportDraft {
  const ReportDraft({
    this.evidence = const [],
    this.vehicleType,
    this.plate = '',
    this.smokeColor,
    this.description = '',
    this.lat,
    this.lng,
    this.address,
    this.municipality,
    this.suggestedAuthorityId,
    this.occurredAt,
  });

  final List<EvidenceFile> evidence;

  // Step 2 · vehicle (US-06)
  final String? vehicleType;
  final String plate;
  final String? smokeColor;
  final String description;

  // Step 3 · location and time (US-07)
  final double? lat;
  final double? lng;
  final String? address;
  final String? municipality;
  final int? suggestedAuthorityId;

  /// Set automatically when step 3 opens; the user cannot edit it (RF-03).
  final DateTime? occurredAt;

  bool get hasLocation => lat != null && lng != null;

  bool get isEmpty =>
      evidence.isEmpty &&
      vehicleType == null &&
      plate.isEmpty &&
      smokeColor == null &&
      description.isEmpty;

  ReportDraft copyWith({
    List<EvidenceFile>? evidence,
    String? vehicleType,
    String? plate,
    String? smokeColor,
    String? description,
    double? lat,
    double? lng,
    DateTime? occurredAt,
  }) {
    return ReportDraft(
      evidence: evidence ?? this.evidence,
      vehicleType: vehicleType ?? this.vehicleType,
      plate: plate ?? this.plate,
      smokeColor: smokeColor ?? this.smokeColor,
      description: description ?? this.description,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      // The address data is kept; use withGeo() to replace it.
      address: address,
      municipality: municipality,
      suggestedAuthorityId: suggestedAuthorityId,
      occurredAt: occurredAt ?? this.occurredAt,
    );
  }

  /// Same draft with the address data replaced (null clears it).
  ReportDraft withGeo({String? address, String? municipality, int? suggestedAuthorityId}) {
    return ReportDraft(
      evidence: evidence,
      vehicleType: vehicleType,
      plate: plate,
      smokeColor: smokeColor,
      description: description,
      lat: lat,
      lng: lng,
      address: address,
      municipality: municipality,
      suggestedAuthorityId: suggestedAuthorityId,
      occurredAt: occurredAt,
    );
  }
}

class ReportDraftController extends Notifier<ReportDraft> {
  @override
  ReportDraft build() => const ReportDraft();

  /// Starts a new, empty report.
  void reset() => state = const ReportDraft();

  bool get canAddEvidence => state.evidence.length < EvidenceLimits.maxFiles;

  int get remainingEvidence => EvidenceLimits.maxFiles - state.evidence.length;

  void addEvidence(EvidenceFile file) {
    if (!canAddEvidence) return;
    state = state.copyWith(evidence: [...state.evidence, file]);
  }

  void removeEvidence(EvidenceFile file) {
    state = state.copyWith(evidence: state.evidence.where((f) => f != file).toList());
  }

  /// Step 3 opens: date and time are taken now, only the first time (RF-03).
  void startLocationStep(DateTime now) {
    if (state.occurredAt == null) state = state.copyWith(occurredAt: now);
  }

  /// New pin position: the previous address no longer applies.
  void setPoint(double lat, double lng) {
    state = state.copyWith(lat: lat, lng: lng).withGeo();
  }

  void setGeo({String? address, String? municipality, int? suggestedAuthorityId}) {
    state = state.withGeo(
      address: address,
      municipality: municipality,
      suggestedAuthorityId: suggestedAuthorityId,
    );
  }

  /// Step 2 saves each change, so going back and forth keeps the data.
  void updateVehicle({
    String? vehicleType,
    String? plate,
    String? smokeColor,
    String? description,
  }) {
    state = state.copyWith(
      vehicleType: vehicleType,
      plate: plate,
      smokeColor: smokeColor,
      description: description,
    );
  }
}

/// Values sent to the API with the text shown to the user (docs/05, docs/06).
const vehicleTypeLabels = {
  'bus': 'Bus o buseta',
  'microbus': 'Microbús',
  'camion': 'Camión',
  'tractomula': 'Tractomula',
  'otro': 'Otro',
};

const smokeColorLabels = {
  'negro': 'Negro',
  'gris': 'Gris',
  'blanco': 'Blanco',
};

const maxDescriptionLength = 500;

final reportDraftProvider =
    NotifierProvider<ReportDraftController, ReportDraft>(ReportDraftController.new);
