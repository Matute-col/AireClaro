import 'package:aireclaro/core/api_error.dart';
import 'package:aireclaro/features/history/report_detail.dart';
import 'package:aireclaro/features/history/report_detail_screen.dart';
import 'package:aireclaro/features/report/authorities_repository.dart';
import 'package:aireclaro/features/report/report_draft.dart';
import 'package:aireclaro/features/report/reports_repository.dart';
import 'package:aireclaro/shared/widgets/auth_image.dart';
import 'package:aireclaro/shared/widgets/osm_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fakes.dart';

ReportDetail sampleDetail() => ReportDetail(
      id: 'r1',
      vehicleType: 'tractomula',
      plate: 'XYZ789',
      smokeColor: 'gris',
      description: 'Humo denso al subir',
      lat: 4.61,
      lng: -74.082,
      address: 'Carrera 19, UPZs de Bogotá, Bogotá ciudad',
      occurredAt: DateTime(2026, 11, 16, 9, 30),
      status: 'generado',
      requesterName: 'Ana Prueba',
      requesterDocType: 'CC',
      requesterDocNumber: '0000000',
      requesterEmail: 'ana@ejemplo.test',
      media: const [
        ReportMedia(id: 'm1', kind: EvidenceKind.photo, sizeBytes: 300000),
        ReportMedia(id: 'm2', kind: EvidenceKind.video, sizeBytes: 3355443),
      ],
      authority: const Authority(
        id: 2,
        code: 'SDA',
        name: 'Secretaría Distrital de Ambiente de Bogotá',
        canEmail: true,
      ),
    );

class FakeDetailRepository extends FakeReportsListRepository {
  ReportDetail? detail;
  ApiException? detailError;

  @override
  Future<ReportDetail> getById(String id) async {
    if (detailError != null) throw detailError!;
    return detail!;
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('es_CO'));

  late FakeDetailRepository repository;

  Future<void> pumpDetail(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: [
      reportsRepositoryProvider.overrideWithValue(repository),
      authTokenProvider.overrideWith((ref) async => null),
      mapTilesEnabledProvider.overrideWithValue(false),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ReportDetailScreen(reportId: 'r1')),
    ));
    await tester.pumpAndSettle();
  }

  setUp(() => repository = FakeDetailRepository());

  testWidgets('shows evidence, data, map, authority and status', (tester) async {
    repository.detail = sampleDetail();
    await pumpDetail(tester);

    expect(find.text('XYZ789'), findsOneWidget);
    expect(find.text('Generado'), findsOneWidget);
    expect(find.textContaining('Tractomula'), findsOneWidget);
    expect(find.textContaining('Humo denso al subir'), findsOneWidget);
    expect(find.textContaining('Carrera 19'), findsOneWidget);
    expect(find.textContaining('Secretaría Distrital de Ambiente'), findsOneWidget);
    expect(find.textContaining('ana@ejemplo.test'), findsOneWidget);
    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
    expect(find.text('1 de 2 · desliza para ver más'), findsOneWidget);
  });

  testWidgets('swiping shows the video card with its size', (tester) async {
    repository.detail = sampleDetail();
    await pumpDetail(tester);

    await tester.fling(find.byType(PageView), const Offset(-800, 0), 1500);
    await tester.pumpAndSettle();
    expect(find.text('Video · 3,2 MB'), findsOneWidget);
    expect(find.text('2 de 2 · desliza para ver más'), findsOneWidget);
  });

  testWidgets('404 (not found or not yours): clear message, no retry', (tester) async {
    repository.detailError = const ApiException(
      code: 'NOT_FOUND',
      message: 'No encontramos este reporte.',
      statusCode: 404,
    );
    await pumpDetail(tester);

    expect(find.text('No encontramos este reporte'), findsOneWidget);
    expect(find.text('Reintentar'), findsNothing);
  });

  testWidgets('no connection: «Reintentar» loads it again', (tester) async {
    repository.detailError = networkError;
    await pumpDetail(tester);
    expect(find.textContaining('No pudimos conectar'), findsOneWidget);

    repository
      ..detailError = null
      ..detail = sampleDetail();
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('XYZ789'), findsOneWidget);
  });
}
