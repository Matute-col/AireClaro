import 'package:aireclaro/features/report/report_draft.dart';
import 'package:aireclaro/features/report/reports_repository.dart';
import 'package:flutter_test/flutter_test.dart';

// US-23 · What the app sends: evidence in «files», then the frames of each video in
// «frames_v<N>» (N = position of the video in «files»), in their order (position 1..4).

const _photo = EvidenceFile(path: '/tmp/a.jpg', kind: EvidenceKind.photo, sizeBytes: 1000);

EvidenceFile _video(String name, FramesStatus status, [int frames = 4]) => EvidenceFile(
      path: '/tmp/$name.mp4',
      kind: EvidenceKind.video,
      sizeBytes: 5000,
      framesStatus: status,
      frames: [for (var i = 1; i <= frames; i++) '/tmp/$name-$i.jpg'],
    );

void main() {
  test('frames go after the evidence, in the field of their video and in order', () {
    final parts = evidenceParts(ReportDraft(evidence: [_photo, _video('v', FramesStatus.ready)]));

    expect(parts, [
      ('files', '/tmp/a.jpg'),
      ('files', '/tmp/v.mp4'),
      ('frames_v1', '/tmp/v-1.jpg'),
      ('frames_v1', '/tmp/v-2.jpg'),
      ('frames_v1', '/tmp/v-3.jpg'),
      ('frames_v1', '/tmp/v-4.jpg'),
    ]);
  });

  test('frames do not count toward the 3 files: 3 files + 4 frames', () {
    final parts = evidenceParts(ReportDraft(
      evidence: [_photo, _photo, _video('v', FramesStatus.ready)],
    ));
    expect(parts.where((p) => p.$1 == 'files'), hasLength(3));
    expect(parts.where((p) => p.$1 == 'frames_v2'), hasLength(4));
  });

  test('only complete extractions are sent (failed or in progress → no frames)', () {
    final parts = evidenceParts(ReportDraft(evidence: [
      _video('a', FramesStatus.failed, 0),
      _video('b', FramesStatus.extracting, 0),
      _video('c', FramesStatus.ready),
    ]));
    expect(parts.map((p) => p.$1).toSet(), {'files', 'frames_v2'});
  });
}
