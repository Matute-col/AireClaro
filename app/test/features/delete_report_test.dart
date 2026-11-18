import 'package:aireclaro/core/api_error.dart';
import 'package:aireclaro/features/history/report_detail.dart';
import 'package:aireclaro/features/history/report_detail_screen.dart';
import 'package:aireclaro/features/report/authorities_repository.dart';
import 'package:aireclaro/features/report/reports_repository.dart';
import 'package:aireclaro/shared/widgets/auth_image.dart';
import 'package:aireclaro/shared/widgets/osm_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fakes.dart';

// US-18 · «Eliminar reporte» in the detail (RF-16, CP-17).

const _id = '3f2a9c1b-0000-4000-8000-000000000000';

class _Repository extends FakeReportsListRepository {
  String status = 'generado';
  final deleted = <String>[];
  ApiException? deleteError;

  @override
  Future<ReportDetail> getById(String id) async => ReportDetail(
    id: _id,
    vehicleType: 'bus',
    plate: 'ABC123',
    smokeColor: 'negro',
    lat: 4.61,
    lng: -74.082,
    occurredAt: DateTime(2026, 11, 17, 9, 30),
    status: status,
    sentVia: status == 'enviado' ? 'email' : null,
    requesterName: 'José Peña Núñez',
    requesterDocType: 'CC',
    requesterDocNumber: 'TEST0001',
    requesterEmail: 'jose@example.com',
    media: const [],
    authority: const Authority(
      id: 2,
      code: 'SDA',
      name: 'Secretaría Distrital de Ambiente de Bogotá',
    ),
  );

  @override
  Future<void> deleteReport(String id) async {
    if (deleteError != null) throw deleteError!;
    deleted.add(id);
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('es_CO'));

  late _Repository repository;

  Future<void> pumpDetail(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [
        reportsRepositoryProvider.overrideWithValue(repository),
        authTokenProvider.overrideWith((ref) async => null),
        mapTilesEnabledProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/reports',
      routes: [
        GoRoute(
          path: '/reports',
          builder: (_, _) => const Scaffold(body: Text('Lista de reportes')),
        ),
        GoRoute(
          path: '/reports/:id',
          builder: (_, state) =>
              ReportDetailScreen(reportId: state.pathParameters['id']!),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.push('/reports/$_id');
    await tester.pumpAndSettle();
  }

  Future<void> tapDelete(WidgetTester tester) async {
    await tester.tap(find.text('Eliminar reporte'));
    await tester.pumpAndSettle();
  }

  setUp(() => repository = _Repository());

  testWidgets(
    'asks for confirmation; «Eliminar» deletes it and goes back to the list',
    (tester) async {
      await pumpDetail(tester);
      await tapDelete(tester);

      expect(find.text('¿Eliminar este reporte?'), findsOneWidget);
      expect(find.textContaining('No se puede deshacer'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await tester.pumpAndSettle();

      expect(repository.deleted, [_id]);
      expect(find.text('Lista de reportes'), findsOneWidget);
      expect(find.text('Reporte eliminado.'), findsOneWidget);
    },
  );

  testWidgets('«Cancelar» deletes nothing', (tester) async {
    await pumpDetail(tester);
    await tapDelete(tester);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(repository.deleted, isEmpty);
    expect(find.text('Eliminar reporte'), findsOneWidget);
  });

  testWidgets(
    'a sent report warns that the request is not withdrawn from the authority',
    (tester) async {
      repository.status = 'enviado';
      await pumpDetail(tester);
      await tapDelete(tester);
      expect(find.textContaining('no se retira'), findsOneWidget);
    },
  );

  testWidgets('error: message and the detail stays', (tester) async {
    repository.deleteError = networkError;
    await pumpDetail(tester);
    await tapDelete(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('No pudimos conectar'), findsOneWidget);
    expect(find.text('Eliminar reporte'), findsOneWidget);
    expect(find.text('Lista de reportes'), findsNothing);
  });
}
