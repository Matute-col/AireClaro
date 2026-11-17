import 'package:aireclaro/core/api_error.dart';
import 'package:aireclaro/features/history/reports_screen.dart';
import 'package:aireclaro/features/report/reports_repository.dart';
import 'package:aireclaro/shared/widgets/auth_image.dart';
import 'package:aireclaro/shared/widgets/status_chip.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fakes.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es_CO'));

  late FakeReportsListRepository repository;

  Future<void> pumpScreen(WidgetTester tester, {int total = 0, ApiException? error}) async {
    repository = FakeReportsListRepository(total: total)..error = error;
    final container = ProviderContainer(overrides: [
      reportsRepositoryProvider.overrideWithValue(repository),
      // No network images in tests: thumbnails show their placeholder.
      authTokenProvider.overrideWith((ref) async => null),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ReportsScreen()),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('empty list: message and «Nuevo reporte»', (tester) async {
    await pumpScreen(tester);
    expect(find.text('Aún no tienes reportes'), findsOneWidget);
    expect(find.text('Nuevo reporte'), findsOneWidget);
  });

  testWidgets('shows plate, type and status of each report, newest first', (tester) async {
    await pumpScreen(tester, total: 3);

    final plates = tester
        .widgetList<Text>(find.textContaining(RegExp(r'^AAA\d{3}$')))
        .map((t) => t.data)
        .toList();
    expect(plates, ['AAA100', 'AAA101', 'AAA102']);
    expect(find.text('Bus o buseta'), findsNWidgets(3));
    expect(find.byType(StatusChip), findsNWidgets(3));
    expect(find.text('Enviado'), findsOneWidget);
    expect(find.text('Generado'), findsNWidgets(2));
    expect(find.text('3 reportes'), findsOneWidget);
  });

  testWidgets('loads the next page when scrolling to the end', (tester) async {
    await pumpScreen(tester, total: 25);
    expect(repository.requestedPages, [1]);

    await tester.fling(find.byType(ListView), const Offset(0, -5000), 3000);
    await tester.pumpAndSettle();
    await tester.fling(find.byType(ListView), const Offset(0, -5000), 3000);
    await tester.pumpAndSettle();

    expect(repository.requestedPages, [1, 2]);
    expect(find.text('25 reportes'), findsOneWidget);
    expect(find.text('AAA124'), findsOneWidget);
  });

  testWidgets('error: «Reintentar» loads the list again', (tester) async {
    await pumpScreen(tester, total: 2, error: networkError);
    expect(find.textContaining('No pudimos conectar'), findsOneWidget);

    repository.error = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('AAA100'), findsOneWidget);
  });
}
