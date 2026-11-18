import 'package:aireclaro/features/history/report_detail.dart';
import 'package:aireclaro/features/pqrsd/done_screen.dart';
import 'package:aireclaro/features/report/authorities_repository.dart';
import 'package:aireclaro/features/report/reports_repository.dart';
import 'package:aireclaro/shared/widgets/status_chip.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fakes.dart';

const _id = '3f2a9c1b-0000-4000-8000-000000000000';

ReportDetail _report({required String status, String? sentVia, String? sendMode}) => ReportDetail(
      id: _id,
      vehicleType: 'bus',
      plate: 'ABC123',
      smokeColor: 'negro',
      lat: 4.61,
      lng: -74.082,
      occurredAt: DateTime(2026, 11, 18, 9, 30),
      status: status,
      sentVia: sentVia,
      sendMode: sendMode,
      requesterName: 'José Peña Núñez',
      requesterDocType: 'CC',
      requesterDocNumber: 'TEST0001',
      requesterEmail: 'jose@example.com',
      media: const [],
      authority: const Authority(
        id: 2,
        code: 'SDA',
        name: 'Secretaría Distrital de Ambiente de Bogotá',
        canEmail: true,
      ),
    );

class _DetailRepository extends FakeReportsListRepository {
  _DetailRepository(this.detail);

  final ReportDetail detail;

  @override
  Future<ReportDetail> getById(String id) async => detail;
}

void main() {
  Future<void> pumpDone(WidgetTester tester, ReportDetail detail) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(overrides: [
      reportsRepositoryProvider.overrideWithValue(_DetailRepository(detail)),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: DoneScreen(reportId: _id)),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('sent by email in test mode: title with the authority and the test-mode notice',
      (tester) async {
    await pumpDone(tester, _report(status: 'enviado', sentVia: 'email', sendMode: 'test'));

    expect(find.text('Solicitud enviada a Secretaría Distrital de Ambiente de Bogotá'), findsOneWidget);
    expect(find.text('Modo de prueba: el correo llegó al buzón de prueba, no a la autoridad.'), findsOneWidget);
    expect(find.textContaining('Revisa la copia que llegó a jose@example.com'), findsOneWidget);
    expect(find.text('Reporte n.º 3F2A9C1B · placa ABC123'), findsOneWidget);
  });

  testWidgets('only generated: «Reporte generado» and the other ways to present it', (tester) async {
    await pumpDone(tester, _report(status: 'generado'));

    expect(find.text('Reporte generado'), findsOneWidget);
    expect(find.textContaining('radicarla en el portal oficial'), findsOneWidget);
    expect(find.textContaining('Modo de prueba'), findsNothing);
  });

  testWidgets('always shows how to follow up (Ley 1755) and the way back', (tester) async {
    await pumpDone(tester, _report(status: 'generado'));

    expect(find.text('¿Cómo hacer seguimiento?'), findsOneWidget);
    expect(find.textContaining('15 días siguientes a la recepción'), findsOneWidget);
    expect(find.text('Ver mis reportes'), findsOneWidget);
    expect(find.text('Volver al inicio'), findsOneWidget);
  });

  group('StatusChip', () {
    Future<void> pumpChip(WidgetTester tester, StatusChip chip) =>
        tester.pumpWidget(MaterialApp(home: Scaffold(body: chip)));

    testWidgets('«Generado», «Enviado por correo» and «Enviado (manual)»', (tester) async {
      await pumpChip(tester, const StatusChip(status: 'generado'));
      expect(find.text('Generado'), findsOneWidget);
      await pumpChip(tester, const StatusChip(status: 'enviado', sentVia: 'email'));
      expect(find.text('Enviado por correo'), findsOneWidget);
      await pumpChip(tester, const StatusChip(status: 'enviado', sentVia: 'manual'));
      expect(find.text('Enviado (manual)'), findsOneWidget);
    });
  });
}
