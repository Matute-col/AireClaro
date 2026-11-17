import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'report_draft.dart';

/// A file returned by the camera or the gallery.
class PickedMedia {
  const PickedMedia({required this.path, required this.isVideo, required this.sizeBytes});

  final String path;
  final bool isVideo;
  final int sizeBytes;

  /// HEIC/HEIF photos are not accepted by the API (docs/05).
  bool get isUnsupportedFormat {
    final lower = path.toLowerCase();
    return lower.endsWith('.heic') || lower.endsWith('.heif');
  }
}

/// Opens the system camera and gallery (image_picker). No CAMERA permission
/// is declared: the system camera app does not need it (docs/04).
/// Photos are reduced on the phone: longest side 1600 px, quality 80 (RNF-02).
class EvidencePicker {
  EvidencePicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const _maxSide = 1600.0;
  static const _quality = 80;
  static const _videoExtensions = {'mp4', 'mov', '3gp', 'mkv', 'webm'};

  Future<PickedMedia?> takePhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: _maxSide,
      maxHeight: _maxSide,
      imageQuality: _quality,
    );
    return file == null ? null : _toPicked(file, isVideo: false);
  }

  /// The 15 s limit is applied by the camera app (some models ignore it).
  Future<PickedMedia?> recordVideo() async {
    final file = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: EvidenceLimits.maxVideoSeconds),
    );
    return file == null ? null : _toPicked(file, isVideo: true);
  }

  /// Photos and videos from the gallery, at most [limit] files.
  Future<List<PickedMedia>> pickFromGallery({required int limit}) async {
    final files = await _picker.pickMultipleMedia(
      maxWidth: _maxSide,
      maxHeight: _maxSide,
      imageQuality: _quality,
      limit: limit,
    );
    return Future.wait(files.take(limit).map((f) => _toPicked(f, isVideo: _looksLikeVideo(f))));
  }

  static bool _looksLikeVideo(XFile file) {
    final mime = file.mimeType;
    if (mime != null) return mime.startsWith('video/');
    final ext = file.path.split('.').last.toLowerCase();
    return _videoExtensions.contains(ext);
  }

  static Future<PickedMedia> _toPicked(XFile file, {required bool isVideo}) async {
    return PickedMedia(path: file.path, isVideo: isVideo, sizeBytes: await file.length());
  }
}

final evidencePickerProvider = Provider<EvidencePicker>((ref) => EvidencePicker());
