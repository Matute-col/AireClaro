import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/user.dart';
import 'frame_extractor.dart';

enum EvidenceKind { photo, video }

/// US-23 · Frames of a video: being extracted, ready (4 JPEG) or failed (none).
enum FramesStatus { none, extracting, ready, failed }

/// A photo or video chosen for the report (still only on the phone).
class EvidenceFile {
  const EvidenceFile({
    required this.path,
    required this.kind,
    required this.sizeBytes,
    this.frames = const [],
    this.framesStatus = FramesStatus.none,
  });

  final String path;
  final EvidenceKind kind;
  final int sizeBytes;

  /// Videos only: paths of the extracted frames, in order (position 1..4).
  final List<String> frames;
  final FramesStatus framesStatus;

  bool get isVideo => kind == EvidenceKind.video;

  EvidenceFile withFrames(FramesStatus status, [List<String> frames = const []]) => EvidenceFile(
        path: path,
        kind: kind,
        sizeBytes: sizeBytes,
        frames: frames,
        framesStatus: status,
      );
}

/// Limits from docs/05 (the API checks them again).
class EvidenceLimits {
  EvidenceLimits._();

  static const maxFiles = 3;
  static const maxPhotoBytes = 8 * 1024 * 1024;
  static const maxVideoBytes = 25 * 1024 * 1024;
  static const maxVideoSeconds = 15;
}

/// Address found for the pin (GET /geo/reverse). Replaced as a whole when the pin moves.
class GeoData {
  const GeoData({this.address, this.municipality, this.suggestedAuthorityId});

  final String? address;
  final String? municipality;
  final int? suggestedAuthorityId;
}

/// Step 4 · requester (peticionario), prefilled from the profile and editable.
class RequesterData {
  const RequesterData({
    this.name = '',
    this.docType,
    this.docNumber = '',
    this.email = '',
    this.phone = '',
  });

  factory RequesterData.fromUser(User user) => RequesterData(
        name: user.fullName,
        docType: user.docType,
        docNumber: user.docNumber,
        email: user.email,
        phone: user.phone ?? '',
      );

  final String name;
  final String? docType;
  final String docNumber;
  final String email;
  final String phone;

  bool get isEmpty => name.isEmpty && docNumber.isEmpty && email.isEmpty;

  RequesterData copyWith({
    String? name,
    String? docType,
    String? docNumber,
    String? email,
    String? phone,
  }) {
    return RequesterData(
      name: name ?? this.name,
      docType: docType ?? this.docType,
      docNumber: docNumber ?? this.docNumber,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }
}

/// The report being created, kept in memory during steps 1–4 and the review (docs/06).
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
    this.geo = const GeoData(),
    this.occurredAt,
    this.requester = const RequesterData(),
    this.chosenAuthorityId,
  });

  // Step 1 · evidence (US-05)
  final List<EvidenceFile> evidence;

  // Step 2 · vehicle (US-06)
  final String? vehicleType;
  final String plate;
  final String? smokeColor;
  final String description;

  // Step 3 · location and time (US-07)
  final double? lat;
  final double? lng;
  final GeoData geo;

  /// Set automatically when step 3 opens; the user cannot edit it (RF-03).
  final DateTime? occurredAt;

  // Step 4 · requester (US-08)
  final RequesterData requester;

  // Review · authority picked with «Cambiar» (US-09); null = use the suggestion.
  final int? chosenAuthorityId;

  String? get address => geo.address;
  String? get municipality => geo.municipality;
  int? get suggestedAuthorityId => geo.suggestedAuthorityId;

  /// Authority that will receive the request: the user's choice or the suggestion.
  int? get authorityId => chosenAuthorityId ?? geo.suggestedAuthorityId;

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
    GeoData? geo,
    DateTime? occurredAt,
    RequesterData? requester,
    int? chosenAuthorityId,
  }) {
    return ReportDraft(
      evidence: evidence ?? this.evidence,
      vehicleType: vehicleType ?? this.vehicleType,
      plate: plate ?? this.plate,
      smokeColor: smokeColor ?? this.smokeColor,
      description: description ?? this.description,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      geo: geo ?? this.geo,
      occurredAt: occurredAt ?? this.occurredAt,
      requester: requester ?? this.requester,
      chosenAuthorityId: chosenAuthorityId ?? this.chosenAuthorityId,
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
    state = state.copyWith(evidence: state.evidence.where((f) => f.path != file.path).toList());
  }

  /// True while a video of the report is still extracting its frames.
  bool get isExtractingFrames =>
      state.evidence.any((f) => f.framesStatus == FramesStatus.extracting);

  /// US-23 · Extracts the 4 frames of the video at [videoPath]. Returns false only if
  /// it failed and the video is still in the report: the report continues without
  /// frames and the screen tells the user.
  Future<bool> extractFrames(String videoPath) async {
    _updateVideo(videoPath, (f) => f.withFrames(FramesStatus.extracting));
    try {
      final frames = await ref.read(frameExtractorProvider).extract(videoPath);
      _updateVideo(videoPath, (f) => f.withFrames(FramesStatus.ready, frames));
      return true;
    } catch (_) {
      final stillThere = state.evidence.any((f) => f.path == videoPath);
      _updateVideo(videoPath, (f) => f.withFrames(FramesStatus.failed));
      return !stillThere;
    }
  }

  /// Replaces one evidence file; does nothing if the user already removed it.
  void _updateVideo(String path, EvidenceFile Function(EvidenceFile) change) {
    if (!state.evidence.any((f) => f.path == path)) return;
    state = state.copyWith(
      evidence: [for (final f in state.evidence) f.path == path ? change(f) : f],
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

  /// Step 3 opens: date and time are taken now, only the first time (RF-03).
  void startLocationStep(DateTime now) {
    if (state.occurredAt == null) state = state.copyWith(occurredAt: now);
  }

  /// New pin position: the previous address no longer applies.
  void setPoint(double lat, double lng) {
    state = state.copyWith(lat: lat, lng: lng, geo: const GeoData());
  }

  void setGeo({String? address, String? municipality, int? suggestedAuthorityId}) {
    state = state.copyWith(
      geo: GeoData(
        address: address,
        municipality: municipality,
        suggestedAuthorityId: suggestedAuthorityId,
      ),
    );
  }

  /// Step 4 opens: fill the requester from the profile, only if still empty.
  void prefillRequester(User? user) {
    if (user != null && state.requester.isEmpty) {
      state = state.copyWith(requester: RequesterData.fromUser(user));
    }
  }

  void updateRequester({
    String? name,
    String? docType,
    String? docNumber,
    String? email,
    String? phone,
  }) {
    state = state.copyWith(
      requester: state.requester.copyWith(
        name: name,
        docType: docType,
        docNumber: docNumber,
        email: email,
        phone: phone,
      ),
    );
  }

  /// Review · «Cambiar» authority.
  void chooseAuthority(int authorityId) {
    state = state.copyWith(chosenAuthorityId: authorityId);
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
