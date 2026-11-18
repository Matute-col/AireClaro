import 'dart:io';

import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail_platform_interface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

/// The frames could not be extracted; the report continues without them (US-23).
class FrameExtractionException implements Exception {
  const FrameExtractionException(this.reason);

  final String reason;

  @override
  String toString() => 'FrameExtractionException($reason)';
}

/// US-23 · Extracts 4 JPEG frames of a video at 10 %, 35 %, 65 % and 90 % of its
/// duration, each one ≤ 300 KB (the API checks the same limit).
class FrameExtractor {
  static const percents = [0.10, 0.35, 0.65, 0.90];
  static const maxFrameBytes = 300 * 1024;

  /// First try, and a smaller one if a frame is still too heavy.
  static const _attempts = [(side: 720, quality: 70), (side: 480, quality: 50)];

  /// Returns the 4 frame paths in order (position 1..4). Throws FrameExtractionException.
  Future<List<String>> extract(String videoPath) async {
    final duration = await _duration(videoPath);
    if (duration <= Duration.zero) {
      throw const FrameExtractionException('duración desconocida');
    }

    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final plugin = FcNativeVideoThumbnail();
    final frames = <String>[];

    for (var i = 0; i < percents.length; i++) {
      final at = (duration.inMilliseconds * percents[i]).round();
      final dest = '${dir.path}/fotograma-$stamp-${i + 1}.jpg';
      if (!await _saveFrame(plugin, videoPath, dest, at)) {
        throw FrameExtractionException('no se pudo extraer el fotograma ${i + 1}');
      }
      frames.add(dest);
    }
    return frames;
  }

  /// Saves one frame at [atMs]; true when it exists and weighs ≤ 300 KB.
  Future<bool> _saveFrame(FcNativeVideoThumbnail plugin, String src, String dest, int atMs) async {
    for (final attempt in _attempts) {
      final created = await plugin.saveThumbnailToFile(
        srcFile: src,
        destFile: dest,
        width: attempt.side,
        height: attempt.side,
        quality: attempt.quality,
        format: 'jpeg',
        at: FcVideoThumbnailTime(atMs, FcVideoThumbnailTimeUnit.milliseconds),
      );
      if (created && await File(dest).length() <= maxFrameBytes) return true;
    }
    return false;
  }

  /// video_player is used ONLY to read the duration (the app does not play videos).
  Future<Duration> _duration(String path) async {
    final controller = VideoPlayerController.file(File(path));
    try {
      await controller.initialize();
      return controller.value.duration;
    } finally {
      await controller.dispose();
    }
  }
}

final frameExtractorProvider = Provider<FrameExtractor>((ref) => FrameExtractor());
