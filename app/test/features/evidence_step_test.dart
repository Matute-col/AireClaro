import 'dart:async';

import 'package:aireclaro/features/report/evidence_picker.dart';
import 'package:aireclaro/features/report/evidence_step_screen.dart';
import 'package:aireclaro/features/report/frame_extractor.dart';
import 'package:aireclaro/features/report/report_draft.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fakes.dart';

/// Returns prepared files instead of opening the camera or the gallery.
class FakeEvidencePicker implements EvidencePicker {
  PickedMedia? nextPhoto;
  PickedMedia? nextVideo;
  List<PickedMedia> nextGallery = const [];
  int? lastGalleryLimit;

  @override
  Future<PickedMedia?> takePhoto() async => nextPhoto;

  @override
  Future<PickedMedia?> recordVideo() async => nextVideo;

  @override
  Future<List<PickedMedia>> pickFromGallery({required int limit}) async {
    lastGalleryLimit = limit;
    return nextGallery.take(limit).toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _mb = 1024 * 1024;
PickedMedia photo(String name, {int size = 500000}) =>
    PickedMedia(path: '/tmp/$name.jpg', isVideo: false, sizeBytes: size);
PickedMedia video(String name, {int size = 5 * _mb}) =>
    PickedMedia(path: '/tmp/$name.mp4', isVideo: true, sizeBytes: size);

void main() {
  late FakeEvidencePicker picker;
  late FakeFrameExtractor extractor;
  late ProviderContainer container;

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    picker = FakeEvidencePicker();
    extractor = FakeFrameExtractor();
    container = ProviderContainer(overrides: [
      evidencePickerProvider.overrideWithValue(picker),
      frameExtractorProvider.overrideWithValue(extractor),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: EvidenceStepScreen()),
    ));
  }

  Finder button(String label) => find.ancestor(of: find.text(label), matching: find.bySubtype<ButtonStyleButton>());
  bool enabled(WidgetTester tester, String label) =>
      tester.widget<ButtonStyleButton>(button(label)).onPressed != null;
  List<EvidenceFile> evidence() => container.read(reportDraftProvider).evidence;

  testWidgets('«Siguiente» is enabled only with at least one file', (tester) async {
    await pumpScreen(tester);
    expect(enabled(tester, 'Siguiente'), isFalse);

    picker.nextPhoto = photo('a');
    await tester.tap(find.text('Tomar foto'));
    await tester.pumpAndSettle();

    expect(evidence(), hasLength(1));
    expect(enabled(tester, 'Siguiente'), isTrue);
  });

  testWidgets('videos show a «Video» card with the size', (tester) async {
    await pumpScreen(tester);
    picker.nextVideo = video('v', size: (3.2 * _mb).round());
    await tester.tap(find.text('Grabar video (máx. 15 s)'));
    await tester.pumpAndSettle();

    expect(find.text('Video'), findsOneWidget);
    expect(find.text('3,2 MB'), findsOneWidget);
  });

  testWidgets('maximum 3 files: buttons are disabled when full', (tester) async {
    await pumpScreen(tester);
    picker.nextGallery = [photo('a'), photo('b'), video('c'), photo('d')];
    await tester.tap(find.text('Elegir de la galería'));
    await tester.pumpAndSettle();

    expect(picker.lastGalleryLimit, 3);
    expect(evidence(), hasLength(3));
    expect(find.text('3 de 3 archivos'), findsOneWidget);
    expect(enabled(tester, 'Tomar foto'), isFalse);
    expect(enabled(tester, 'Elegir de la galería'), isFalse);
  });

  testWidgets('a file can be removed', (tester) async {
    await pumpScreen(tester);
    picker.nextGallery = [photo('a'), photo('b')];
    await tester.tap(find.text('Elegir de la galería'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Quitar').first);
    await tester.pumpAndSettle();
    expect(evidence(), hasLength(1));
  });

  testWidgets('too large or HEIC files are rejected with a message', (tester) async {
    await pumpScreen(tester);
    picker.nextGallery = [
      video('grande', size: 26 * _mb),
      const PickedMedia(path: '/tmp/foto.heic', isVideo: false, sizeBytes: 1000),
    ];
    await tester.tap(find.text('Elegir de la galería'));
    await tester.pump();

    expect(evidence(), isEmpty);
    expect(find.textContaining('El video supera 25 MB'), findsOneWidget);
    expect(find.textContaining('HEIC'), findsOneWidget);
  });

  group('US-23 · video frames', () {
    Future<void> addVideo(WidgetTester tester) async {
      picker.nextVideo = video('v');
      await tester.tap(find.text('Grabar video (máx. 15 s)'));
      await tester.pump();
    }

    testWidgets('adding a video extracts 4 frames, in order', (tester) async {
      await pumpScreen(tester);
      await addVideo(tester);
      await tester.pumpAndSettle();

      final file = evidence().single;
      expect(extractor.calls, ['/tmp/v.mp4']);
      expect(file.framesStatus, FramesStatus.ready);
      expect(file.frames, [for (var i = 1; i <= 4; i++) '/tmp/v.mp4-fotograma-$i.jpg']);
      expect(find.text('4 fotogramas'), findsOneWidget);
    });

    testWidgets('shows that the frames are being extracted', (tester) async {
      await pumpScreen(tester);
      extractor.gate = Completer<void>();
      await addVideo(tester);

      expect(find.text('Fotogramas…'), findsOneWidget);
      expect(evidence().single.framesStatus, FramesStatus.extracting);
      extractor.gate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('if extraction fails the report continues without frames and says so', (tester) async {
      await pumpScreen(tester);
      extractor.fail = true;
      await addVideo(tester);
      await tester.pumpAndSettle();

      expect(evidence().single.framesStatus, FramesStatus.failed);
      expect(evidence().single.frames, isEmpty);
      expect(find.text('Sin fotogramas'), findsOneWidget);
      expect(
        find.text('No pudimos extraer los fotogramas del video. El reporte seguirá sin ellos.'),
        findsOneWidget,
      );
      // «Siguiente» still works: the report continues.
      expect(enabled(tester, 'Siguiente'), isTrue);
    });

    testWidgets('removing the video while extracting: no warning', (tester) async {
      await pumpScreen(tester);
      extractor
        ..gate = Completer<void>()
        ..fail = true;
      await addVideo(tester);
      await tester.tap(find.byTooltip('Quitar'));
      await tester.pump();
      extractor.gate!.complete();
      await tester.pumpAndSettle();

      expect(evidence(), isEmpty);
      expect(find.textContaining('No pudimos extraer'), findsNothing);
    });

    testWidgets('photos do not extract frames', (tester) async {
      await pumpScreen(tester);
      picker.nextPhoto = photo('a');
      await tester.tap(find.text('Tomar foto'));
      await tester.pumpAndSettle();
      expect(extractor.calls, isEmpty);
    });
  });
}
