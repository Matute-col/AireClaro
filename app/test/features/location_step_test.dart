import 'package:aireclaro/core/api_error.dart';
import 'package:aireclaro/features/report/geo_repository.dart';
import 'package:aireclaro/features/report/location_service.dart';
import 'package:aireclaro/features/report/location_step_screen.dart';
import 'package:aireclaro/features/report/report_draft.dart';
import 'package:aireclaro/shared/widgets/osm_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

class FakeLocationService implements LocationService {
  FakeLocationService(this.results);

  /// One result per call; the last one repeats.
  final List<LocationResult> results;
  int calls = 0;
  LocationIssue? openedSettingsFor;

  @override
  Future<LocationResult> current() async {
    final result = results[calls < results.length ? calls : results.length - 1];
    calls++;
    return result;
  }

  @override
  Future<void> openSettings(LocationIssue issue) async => openedSettingsFor = issue;
}

class FakeGeoRepository implements GeoRepository {
  GeoResult result = const GeoResult(
    address: 'Carrera 3A, Ubaté, Soacha ciudad',
    municipality: 'Soacha ciudad',
    suggestedAuthorityId: 1,
  );
  ApiException? error;
  final calls = <(double, double)>[];

  @override
  Future<GeoResult> reverse(double lat, double lng) async {
    calls.add((lat, lng));
    if (error != null) throw error!;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() => initializeDateFormatting('es_CO'));

  late FakeLocationService location;
  late FakeGeoRepository geo;
  late ProviderContainer container;

  Future<void> pumpScreen(WidgetTester tester, List<LocationResult> results) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    location = FakeLocationService(results);
    geo = FakeGeoRepository();
    container = ProviderContainer(overrides: [
      locationServiceProvider.overrideWithValue(location),
      geoRepositoryProvider.overrideWithValue(geo),
      mapTilesEnabledProvider.overrideWithValue(false),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: LocationStepScreen()),
    ));
    await tester.pump(); // microtask: start step and read GPS
    await tester.pump(const Duration(seconds: 1)); // debounce before the address lookup
    await tester.pump();
  }

  ReportDraft draft() => container.read(reportDraftProvider);
  bool nextEnabled(WidgetTester tester) =>
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Siguiente')).onPressed != null;

  testWidgets('GPS position: pin, address, suggested authority and fixed date', (tester) async {
    await pumpScreen(tester, [const LocationResult.ok(4.579, -74.217)]);

    expect(draft().lat, 4.579);
    expect(draft().lng, -74.217);
    expect(geo.calls, [(4.579, -74.217)]);
    expect(find.text('Carrera 3A, Ubaté, Soacha ciudad'), findsOneWidget);
    expect(draft().suggestedAuthorityId, 1);
    expect(draft().occurredAt, isNotNull);
    expect(find.text(formatReportDate(draft().occurredAt!)), findsOneWidget);
    expect(nextEnabled(tester), isTrue);
  });

  testWidgets('the OpenStreetMap attribution is always visible', (tester) async {
    await pumpScreen(tester, [const LocationResult.failed(LocationIssue.denied)]);
    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
  });

  testWidgets('permission denied: notice and «Activar ubicación» asks again', (tester) async {
    await pumpScreen(tester, [
      const LocationResult.failed(LocationIssue.denied),
      const LocationResult.ok(4.61, -74.082),
    ]);

    expect(find.text('Necesitamos tu ubicación para registrar dónde ocurrió.'), findsOneWidget);
    expect(nextEnabled(tester), isFalse);

    await tester.tap(find.text('Activar ubicación'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(location.calls, 2);
    expect(draft().lat, 4.61);
    expect(nextEnabled(tester), isTrue);
  });

  testWidgets('permission denied forever: «Activar ubicación» opens the settings', (tester) async {
    await pumpScreen(tester, [const LocationResult.failed(LocationIssue.deniedForever)]);
    await tester.tap(find.text('Activar ubicación'));
    await tester.pump();
    expect(location.openedSettingsFor, LocationIssue.deniedForever);
  });

  testWidgets('if the address fails the user can still continue', (tester) async {
    location = FakeLocationService([const LocationResult.ok(4.579, -74.217)]);
    await pumpScreenWithGeoError(tester, location);

    expect(find.textContaining('No pudimos obtener la dirección'), findsOneWidget);
    expect(nextEnabled(tester), isTrue);
  });

  testWidgets('the date is taken only the first time the step opens', (tester) async {
    final first = DateTime(2026, 11, 16, 8, 30);
    container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(reportDraftProvider.notifier).startLocationStep(first);
    container.read(reportDraftProvider.notifier).startLocationStep(DateTime(2026, 11, 16, 9));
    expect(container.read(reportDraftProvider).occurredAt, first);
  });
}

/// Same as pumpScreen, but the geocoder answers 502.
Future<void> pumpScreenWithGeoError(WidgetTester tester, FakeLocationService location) async {
  tester.view.physicalSize = const Size(1080, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final geo = FakeGeoRepository()
    ..error = const ApiException(
      code: 'GEOCODER_UNAVAILABLE',
      message: 'No pudimos obtener la dirección en este momento.',
      statusCode: 502,
    );
  final container = ProviderContainer(overrides: [
    locationServiceProvider.overrideWithValue(location),
    geoRepositoryProvider.overrideWithValue(geo),
    mapTilesEnabledProvider.overrideWithValue(false),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: LocationStepScreen()),
  ));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();
}
