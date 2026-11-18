import 'package:aireclaro/core/api_error.dart';
import 'package:aireclaro/core/router.dart';
import 'package:aireclaro/features/report/authorities_repository.dart';
import 'package:aireclaro/features/report/report_draft.dart';
import 'package:aireclaro/features/report/reports_repository.dart';
import 'package:aireclaro/features/report/review_screen.dart';
import 'package:aireclaro/shared/widgets/osm_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fakes.dart';

const _authorities = [
  Authority(id: 1, code: 'CAR', name: 'Corporación Autónoma Regional de Cundinamarca (CAR)', canEmail: true),
  Authority(id: 2, code: 'SDA', name: 'Secretaría Distrital de Ambiente de Bogotá', canEmail: true),
  Authority(id: 3, code: 'SDM', name: 'Secretaría Distrital de Movilidad de Bogotá'),
];

class FakeAuthoritiesRepository implements AuthoritiesRepository {
  @override
  Future<List<Authority>> list() async => _authorities;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeReportsRepository implements ReportsRepository {
  ApiException? error;
  ReportDraft? sent;

  @override
  Future<String> create(ReportDraft draft, {void Function(double progress)? onProgress}) async {
    sent = draft;
    onProgress?.call(0.5);
    onProgress?.call(1);
    if (error != null) throw error!;
    return 'new-report-id';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ReportDraft completeDraft({int? suggested = 1}) => ReportDraft(
      evidence: const [
        EvidenceFile(path: '/tmp/a.jpg', kind: EvidenceKind.photo, sizeBytes: 1000),
      ],
      vehicleType: 'bus',
      plate: 'ABC123',
      smokeColor: 'negro',
      description: 'Humo denso',
      lat: 4.579,
      lng: -74.217,
      geo: GeoData(
        address: 'Carrera 3A, Ubaté, Soacha ciudad',
        municipality: 'Soacha ciudad',
        suggestedAuthorityId: suggested,
      ),
      occurredAt: DateTime(2026, 11, 16, 9, 30),
      requester: RequesterData.fromUser(testUser),
    );

void main() {
  setUpAll(() => initializeDateFormatting('es_CO'));

  late FakeReportsRepository reports;
  late ProviderContainer container;

  /// [settle] false: for screens with endless animations (e.g. extracting frames).
  Future<void> pumpReview(WidgetTester tester, ReportDraft draft, {bool settle = true}) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    reports = FakeReportsRepository();
    container = ProviderContainer(overrides: [
      authoritiesRepositoryProvider.overrideWithValue(FakeAuthoritiesRepository()),
      reportsRepositoryProvider.overrideWithValue(reports),
      mapTilesEnabledProvider.overrideWithValue(false),
    ]);
    addTearDown(container.dispose);
    container.read(reportDraftProvider.notifier).state = draft;

    final router = GoRouter(
      initialLocation: Routes.reportReview,
      routes: [
        GoRoute(path: Routes.home, builder: (_, _) => const Scaffold(body: Text('Pantalla de inicio'))),
        GoRoute(path: Routes.reportReview, builder: (_, _) => const ReviewScreen()),
        GoRoute(
          path: '/report/:id/preview',
          builder: (_, state) => Scaffold(
            body: Text('Vista previa ${state.pathParameters['id']} ${state.uri.query}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  FilledButton generate(WidgetTester tester) =>
      tester.widget<FilledButton>(find.ancestor(
        of: find.text('Generar solicitud'),
        matching: find.bySubtype<FilledButton>(),
      ));

  test('reportFormFields maps the draft to the API fields', () {
    final fields = reportFormFields(completeDraft());
    expect(fields['plate'], 'ABC123');
    expect(fields['authority_id'], '1');
    expect(fields['lat'], '4.579');
    expect(fields['requester_email'], testUser.email);
    expect(DateTime.parse(fields['occurred_at']!).isUtc, isTrue);
  });

  testWidgets('shows the summary and the suggested authority', (tester) async {
    await pumpReview(tester, completeDraft());

    expect(find.text('Revisa tu reporte'), findsOneWidget);
    expect(find.textContaining('ABC123'), findsOneWidget);
    expect(find.textContaining('Carrera 3A, Ubaté, Soacha ciudad'), findsOneWidget);
    expect(find.textContaining('Corporación Autónoma Regional'), findsOneWidget);
    expect(find.textContaining('Sugerida según la ubicación'), findsOneWidget);
    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
    expect(generate(tester).onPressed, isNotNull);
  });

  testWidgets('«Cambiar» lets the user pick another authority', (tester) async {
    await pumpReview(tester, completeDraft());
    await tester.tap(find.text('Cambiar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Secretaría Distrital de Ambiente de Bogotá'));
    await tester.pumpAndSettle();

    expect(container.read(reportDraftProvider).authorityId, 2);
    expect(find.textContaining('Elegida por ti'), findsOneWidget);
  });

  testWidgets('without a suggestion the user must choose before generating', (tester) async {
    await pumpReview(tester, completeDraft(suggested: null));

    expect(find.textContaining('No pudimos sugerir una autoridad'), findsOneWidget);
    expect(generate(tester).onPressed, isNull);

    await tester.tap(find.text('Elegir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Secretaría Distrital de Movilidad de Bogotá'));
    await tester.pumpAndSettle();
    expect(generate(tester).onPressed, isNotNull);
  });

  testWidgets('«Generar solicitud» creates the report, opens its preview and clears the draft',
      (tester) async {
    await pumpReview(tester, completeDraft());
    await tester.tap(find.text('Generar solicitud'));
    await tester.pumpAndSettle();

    expect(reports.sent?.authorityId, 1);
    expect(find.text('Vista previa new-report-id nuevo=1'), findsOneWidget);
    expect(find.text('Reporte creado.'), findsOneWidget);
    expect(container.read(reportDraftProvider).isEmpty, isTrue);
  });

  testWidgets('no connection: message with «Reintentar» and the data is kept', (tester) async {
    await pumpReview(tester, completeDraft());
    reports.error = networkError;
    await tester.tap(find.text('Generar solicitud'));
    await tester.pumpAndSettle();

    expect(find.textContaining('No pudimos conectar'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(container.read(reportDraftProvider).plate, 'ABC123');

    reports.error = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Vista previa new-report-id nuevo=1'), findsOneWidget);
  });

  testWidgets('server validation errors are listed', (tester) async {
    await pumpReview(tester, completeDraft());
    reports.error = const ApiException(
      code: 'FILE_TOO_LARGE',
      message: 'Cada foto puede pesar máximo 8 MB.',
      statusCode: 413,
    );
    await tester.tap(find.text('Generar solicitud'));
    await tester.pumpAndSettle();

    expect(find.text('Cada foto puede pesar máximo 8 MB.'), findsOneWidget);
    expect(find.text('Reintentar'), findsNothing);
  });

  testWidgets('US-23: «Generar solicitud» waits while the video frames are extracted', (tester) async {
    final draft = completeDraft();
    await pumpReview(
      tester,
      draft.copyWith(evidence: const [
        EvidenceFile(
          path: '/tmp/v.mp4',
          kind: EvidenceKind.video,
          sizeBytes: 5000,
          framesStatus: FramesStatus.extracting,
        ),
      ]),
      settle: false,
    );

    expect(find.textContaining('Extrayendo los fotogramas del video'), findsOneWidget);
    expect(generate(tester).onPressed, isNull);
  });
}
