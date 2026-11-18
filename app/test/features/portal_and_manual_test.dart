import 'package:aireclaro/core/api_error.dart';
import 'package:aireclaro/features/history/report_detail.dart';
import 'package:aireclaro/features/history/report_detail_screen.dart';
import 'package:aireclaro/features/pqrsd/done_screen.dart';
import 'package:aireclaro/features/pqrsd/pqrsd_preview.dart';
import 'package:aireclaro/features/pqrsd/preview_screen.dart';
import 'package:aireclaro/features/report/authorities_repository.dart';
import 'package:aireclaro/features/report/reports_repository.dart';
import 'package:aireclaro/shared/services/url_opener.dart';
import 'package:aireclaro/shared/widgets/auth_image.dart';
import 'package:aireclaro/shared/widgets/osm_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fakes.dart';

// US-22 «Radicar en el portal oficial» and US-14 «Marcar como enviado».

const _id = '3f2a9c1b-0000-4000-8000-000000000000';
const _portal = 'https://www.movilidadbogota.gov.co/radicacionwebsdm/formulario.php';
const _sdm = Authority(
  id: 3,
  code: 'SDM',
  name: 'Secretaría Distrital de Movilidad de Bogotá',
  portalUrl: _portal,
  canEmail: false,
);

class _Repository extends FakeReportsListRepository {
  String status = 'generado';
  String? sentVia;
  int marks = 0;
  ApiException? markError;

  @override
  Future<PqrsdPreview> getPqrsd(String id) async => PqrsdPreview(
        authority: _sdm,
        plate: 'ABC123',
        status: status,
        requesterEmail: 'jose@example.com',
        text: 'HECHOS\n1. …',
        mailMode: 'test',
      );

  @override
  Future<ReportDetail> getById(String id) async => ReportDetail(
        id: _id,
        vehicleType: 'bus',
        plate: 'ABC123',
        smokeColor: 'negro',
        lat: 4.61,
        lng: -74.082,
        occurredAt: DateTime(2026, 11, 18, 9, 30),
        status: status,
        sentVia: sentVia,
        requesterName: 'José Peña Núñez',
        requesterDocType: 'CC',
        requesterDocNumber: 'TEST0001',
        requesterEmail: 'jose@example.com',
        media: const [],
        authority: _sdm,
      );

  @override
  Future<void> markAsSent(String id) async {
    marks++;
    if (markError != null) throw markError!;
    status = 'enviado';
    sentVia = 'manual';
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('es_CO'));

  late _Repository repository;
  late FakeUrlOpener browser;

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(overrides: [
      reportsRepositoryProvider.overrideWithValue(repository),
      urlOpenerProvider.overrideWithValue(browser),
      authTokenProvider.overrideWith((ref) async => null),
      mapTilesEnabledProvider.overrideWithValue(false),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: screen),
    ));
    await tester.pumpAndSettle();
  }

  setUp(() {
    repository = _Repository();
    browser = FakeUrlOpener();
  });

  group('US-22 · Radicar en el portal oficial', () {
    testWidgets('SDM (no verified email): portal yes, email no (CP-24)', (tester) async {
      await pump(tester, const PreviewScreen(reportId: _id));
      expect(find.text('Radicar en el portal oficial'), findsOneWidget);
      expect(find.text('Enviar a la autoridad'), findsNothing);
    });

    testWidgets('opens the official URL in the browser and explains the next step (CP-27)',
        (tester) async {
      await pump(tester, const PreviewScreen(reportId: _id));
      await tester.tap(find.text('Radicar en el portal oficial'));
      await tester.pumpAndSettle();

      expect(browser.opened, [_portal]);
      expect(find.textContaining('Adjunta allí el PDF de la solicitud'), findsOneWidget);
    });

    testWidgets('if the browser cannot open: clear message', (tester) async {
      browser.works = false;
      await pump(tester, const PreviewScreen(reportId: _id));
      await tester.tap(find.text('Radicar en el portal oficial'));
      await tester.pumpAndSettle();
      expect(find.text('No pudimos abrir el navegador. Inténtalo de nuevo.'), findsOneWidget);
    });

    testWidgets('the detail also offers the portal', (tester) async {
      await pump(tester, const ReportDetailScreen(reportId: _id));
      expect(find.text('Radicar en el portal oficial'), findsOneWidget);
    });
  });

  group('US-14 · Marcar como enviado', () {
    testWidgets('confirmation «Reporte generado»: asks first, then becomes «Enviado (manual)»',
        (tester) async {
      await pump(tester, const DoneScreen(reportId: _id));
      expect(find.text('Reporte generado'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Marcar como enviado'));
      await tester.pumpAndSettle();
      expect(find.textContaining('¿Ya presentaste esta solicitud por tu cuenta'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Marcar como enviado'));
      await tester.pumpAndSettle();

      expect(repository.marks, 1);
      expect(find.text('Reporte marcado como enviado'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Marcar como enviado'), findsNothing);
    });

    testWidgets('«Cancelar» changes nothing', (tester) async {
      await pump(tester, const DoneScreen(reportId: _id));
      await tester.tap(find.widgetWithText(OutlinedButton, 'Marcar como enviado'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(repository.marks, 0);
    });

    testWidgets('detail: the chip changes to «Enviado (manual)»', (tester) async {
      await pump(tester, const ReportDetailScreen(reportId: _id));
      expect(find.text('Generado'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Marcar como enviado'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Marcar como enviado'));
      await tester.pumpAndSettle();

      expect(find.text('Enviado (manual)'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Marcar como enviado'), findsNothing);
    });

    testWidgets('already sent (409): message and the status is refreshed', (tester) async {
      repository.markError = const ApiException(
        code: 'ALREADY_SENT',
        message: 'Esta solicitud ya fue enviada.',
        statusCode: 409,
      );
      await pump(tester, const ReportDetailScreen(reportId: _id));
      await tester.tap(find.widgetWithText(OutlinedButton, 'Marcar como enviado'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Marcar como enviado'));
      await tester.pumpAndSettle();
      expect(find.text('Esta solicitud ya fue enviada.'), findsOneWidget);
    });
  });
}
