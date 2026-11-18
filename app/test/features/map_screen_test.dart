import 'package:aireclaro/core/api_error.dart';
import 'package:aireclaro/features/map/map_reports.dart';
import 'package:aireclaro/features/map/map_screen.dart';
import 'package:aireclaro/shared/widgets/osm_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fakes.dart';

/// Answers like GET /map/reports and records the filters it was asked for.
class FakeMapRepository implements MapRepository {
  FakeMapRepository(this.pins);

  List<MapReport> pins;
  ApiException? error;
  final asked = <Map<String, String>>[];

  @override
  Future<List<MapReport>> list(MapFilters filters) async {
    asked.add(filters.toQuery(DateTime(2026, 11, 18)));
    if (error != null) throw error!;
    return pins.where((p) => filters.vehicleTypes.isEmpty || filters.vehicleTypes.contains(p.vehicleType)).toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _pins = [
  MapReport(id: 'a', lat: 4.579, lng: -74.217, vehicleType: 'bus', occurredAt: DateTime(2026, 11, 17, 9, 30)),
  MapReport(id: 'b', lat: 4.61, lng: -74.082, vehicleType: 'camion', occurredAt: DateTime(2026, 11, 18, 7, 5)),
];

void main() {
  setUpAll(() => initializeDateFormatting('es_CO'));

  late FakeMapRepository repository;

  Future<void> pumpMap(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(overrides: [
      mapRepositoryProvider.overrideWithValue(repository),
      mapTilesEnabledProvider.overrideWithValue(false),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: MapScreen()),
    ));
    await tester.pumpAndSettle();
  }

  setUp(() => repository = FakeMapRepository(List.of(_pins)));

  testWidgets('shows one pin per report, the count and the OSM attribution', (tester) async {
    await pumpMap(tester);
    expect(find.byKey(const ValueKey('pin-a')), findsOneWidget);
    expect(find.byKey(const ValueKey('pin-b')), findsOneWidget);
    expect(find.text('2 reportes'), findsOneWidget);
    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
  });

  testWidgets('tapping a pin shows only the vehicle type and the date (CP-18)', (tester) async {
    await pumpMap(tester);
    await tester.tap(find.byKey(const ValueKey('pin-a')));
    await tester.pumpAndSettle();

    final card = find.byType(Card).last;
    expect(find.descendant(of: card, matching: find.text('Bus o buseta')), findsOneWidget);
    expect(
      find.descendant(of: card, matching: find.textContaining('17 de noviembre de 2026')),
      findsOneWidget,
    );
    // Nothing else: no plate, address, photo or person.
    final texts = tester.widgetList<Text>(find.descendant(of: card, matching: find.byType(Text)));
    expect(texts, hasLength(2));
    expect(find.descendant(of: card, matching: find.byType(Image)), findsNothing);

    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.text('Bus o buseta'), findsNWidgets(1)); // only the filter chip remains
  });

  testWidgets('vehicle type chips filter the pins', (tester) async {
    await pumpMap(tester);
    await tester.tap(find.widgetWithText(FilterChip, 'Camión'));
    await tester.pumpAndSettle();

    expect(repository.asked.last, {'vehicle_type': 'camion'});
    expect(find.byKey(const ValueKey('pin-a')), findsNothing);
    expect(find.text('1 reporte'), findsOneWidget);
    expect(find.text('Limpiar filtros'), findsOneWidget);
  });

  testWidgets('date chips ask for the right days (Colombia calendar)', (tester) async {
    await pumpMap(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, '7 días'));
    await tester.pumpAndSettle();
    expect(repository.asked.last, {'from': '2026-11-12', 'to': '2026-11-18'});

    await tester.tap(find.widgetWithText(ChoiceChip, 'Hoy'));
    await tester.pumpAndSettle();
    expect(repository.asked.last, {'from': '2026-11-18', 'to': '2026-11-18'});

    await tester.tap(find.text('Limpiar filtros'));
    await tester.pumpAndSettle();
    expect(repository.asked.last, isEmpty);
  });

  testWidgets('no reports with the filters: clear message', (tester) async {
    repository.pins = [];
    await pumpMap(tester);
    expect(find.text('No hay reportes con estos filtros.'), findsOneWidget);
  });

  testWidgets('error: message with «Reintentar»', (tester) async {
    repository.error = networkError;
    await pumpMap(tester);
    expect(find.textContaining('No pudimos conectar'), findsOneWidget);

    repository.error = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('2 reportes'), findsOneWidget);
  });
}
