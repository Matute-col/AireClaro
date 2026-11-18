import 'package:aireclaro/core/api_error.dart';
import 'package:aireclaro/core/router.dart';
import 'package:aireclaro/features/pqrsd/pqrsd_preview.dart';
import 'package:aireclaro/features/pqrsd/preview_screen.dart';
import 'package:aireclaro/features/report/authorities_repository.dart';
import 'package:aireclaro/features/report/reports_repository.dart';
import 'package:aireclaro/shared/services/file_actions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fakes.dart';

const _reportId = '3f2a9c1b-0000-4000-8000-000000000000';

class FakePreviewRepository extends FakeReportsListRepository {
  ApiException? previewError;
  ApiException? downloadError;
  ApiException? sendError;
  int pdfDownloads = 0;
  int sends = 0;
  bool canEmail = true;
  String status = 'generado';
  String mailMode = 'test';

  @override
  Future<PqrsdPreview> getPqrsd(String id) async {
    if (previewError != null) throw previewError!;
    return PqrsdPreview(
      authority: Authority(
        id: 2,
        code: 'SDA',
        name: 'Secretaría Distrital de Ambiente de Bogotá',
        canEmail: canEmail,
      ),
      plate: 'ABC123',
      status: status,
      requesterEmail: 'jose@example.com',
      text: '16 de noviembre de 2026\n\nSeñores\nSecretaría Distrital de Ambiente de Bogotá\n\n'
          'HECHOS\n1. … José Peña Núñez …\n\nANEXOS\n1. Fotografía 1 (JPG, 1,2 MB).',
      mailMode: mailMode,
    );
  }

  @override
  Future<SendResult> sendReport(String id) async {
    sends++;
    if (sendError != null) throw sendError!;
    status = 'enviado';
    return const SendResult(mode: 'test', evidenceAttached: true);
  }

  @override
  Future<String> downloadPdf(String id) async {
    pdfDownloads++;
    if (downloadError != null) throw downloadError!;
    return '/tmp/solicitud-${shortReportId(id)}.pdf';
  }
}

void main() {
  late FakePreviewRepository repository;
  late FakeFileActions files;

  Future<void> pumpPreview(WidgetTester tester, {bool justCreated = false}) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: [
      reportsRepositoryProvider.overrideWithValue(repository),
      fileActionsProvider.overrideWithValue(files),
    ]);
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: Routes.reportPreview(_reportId, justCreated: justCreated),
      routes: [
        GoRoute(
          path: '/report/:id/preview',
          builder: (_, state) => PreviewScreen(
            reportId: state.pathParameters['id']!,
            justCreated: state.uri.queryParameters['nuevo'] == '1',
          ),
        ),
        GoRoute(
          path: '/reports/:id',
          builder: (_, state) => Scaffold(body: Text('Detalle ${state.pathParameters['id']}')),
        ),
        GoRoute(
          path: '/report/:id/done',
          builder: (_, state) => Scaffold(body: Text('Confirmación ${state.pathParameters['id']}')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
  }

  setUp(() {
    repository = FakePreviewRepository();
    files = FakeFileActions();
  });

  testWidgets('shows the authority and the text of the request', (tester) async {
    await pumpPreview(tester);

    expect(find.text('Vista previa de la solicitud'), findsOneWidget);
    expect(find.text('Secretaría Distrital de Ambiente de Bogotá'), findsOneWidget);
    expect(find.textContaining('José Peña Núñez'), findsOneWidget);
    expect(find.textContaining('ANEXOS'), findsOneWidget);
  });

  testWidgets('«Descargar PDF» downloads it with the session and opens it', (tester) async {
    await pumpPreview(tester);
    await tester.tap(find.text('Descargar PDF'));
    await tester.pumpAndSettle();

    expect(files.opened, ['/tmp/solicitud-3F2A9C1B.pdf']);
  });

  testWidgets('«Compartir» opens the share menu with the PDF; the download is reused',
      (tester) async {
    await pumpPreview(tester);
    await tester.tap(find.text('Descargar PDF'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compartir'));
    await tester.pumpAndSettle();

    expect(files.shared.single.$1, '/tmp/solicitud-3F2A9C1B.pdf');
    expect(files.shared.single.$2, 'application/pdf');
    expect(files.shared.single.$3, contains('ABC123'));
    expect(repository.pdfDownloads, 1);
  });

  testWidgets('download error: message with «Reintentar»', (tester) async {
    await pumpPreview(tester);
    repository.downloadError = networkError;
    await tester.tap(find.text('Descargar PDF'));
    await tester.pumpAndSettle();

    expect(find.textContaining('No pudimos conectar'), findsOneWidget);
    expect(files.opened, isEmpty);

    repository.downloadError = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(files.opened, hasLength(1));
  });

  testWidgets('no app to open PDFs: clear message', (tester) async {
    await pumpPreview(tester);
    files.openProblem = 'No hay una app en el teléfono para abrir este archivo.';
    await tester.tap(find.text('Descargar PDF'));
    await tester.pumpAndSettle();
    expect(find.text('No hay una app en el teléfono para abrir este archivo.'), findsOneWidget);
  });

  testWidgets('«Continuar» only right after creating the report',
      (tester) async {
    await pumpPreview(tester);
    expect(find.text('Continuar'), findsNothing);
  });

  testWidgets('just created: «Continuar» goes to the confirmation', (tester) async {
    await pumpPreview(tester, justCreated: true);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmación $_reportId'), findsOneWidget);
  });

  testWidgets('preview error: «Reintentar» loads it again', (tester) async {
    repository.previewError = networkError;
    await pumpPreview(tester);
    expect(find.textContaining('No pudimos conectar'), findsOneWidget);

    repository.previewError = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ANEXOS'), findsOneWidget);
  });

  group('US-21 · «Enviar a la autoridad»', () {
    Future<void> confirmSend(WidgetTester tester) async {
      await tester.tap(find.text('Enviar a la autoridad'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
      await tester.pumpAndSettle();
    }

    testWidgets('visible with a verified email and while not sent', (tester) async {
      await pumpPreview(tester);
      expect(find.text('Enviar a la autoridad'), findsOneWidget);
    });

    testWidgets('authority without a verified email (SDM): no button (CP-24)', (tester) async {
      repository.canEmail = false;
      await pumpPreview(tester);
      expect(find.text('Enviar a la autoridad'), findsNothing);
    });

    testWidgets('already sent: no button and a notice', (tester) async {
      repository.status = 'enviado';
      await pumpPreview(tester);
      expect(find.text('Enviar a la autoridad'), findsNothing);
      expect(find.text('Esta solicitud ya fue enviada.'), findsOneWidget);
    });

    testWidgets('MAIL_MODE=off: no button', (tester) async {
      repository.mailMode = 'off';
      await pumpPreview(tester);
      expect(find.text('Enviar a la autoridad'), findsNothing);
    });

    testWidgets('dialog: authority, copy and test mode; «Cancelar» sends nothing', (tester) async {
      await pumpPreview(tester);
      await tester.tap(find.text('Enviar a la autoridad'));
      await tester.pumpAndSettle();

      expect(find.textContaining('a Secretaría Distrital de Ambiente de Bogotá'), findsOneWidget);
      expect(find.textContaining('Recibirás una copia en jose@example.com'), findsOneWidget);
      expect(
        find.text('Modo de prueba: el correo va a un buzón de prueba, no a la autoridad.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(repository.sends, 0);
    });

    testWidgets('«Enviar» sends once and opens the confirmation (CP-23)', (tester) async {
      await pumpPreview(tester);
      await confirmSend(tester);

      expect(repository.sends, 1);
      expect(find.text('Confirmación $_reportId'), findsOneWidget);
    });

    testWidgets('SMTP failure (502): message with «Reintentar», then it works (CP-26)', (tester) async {
      await pumpPreview(tester);
      repository.sendError = const ApiException(
        code: 'MAIL_SEND_FAILED',
        message: 'No pudimos enviar el correo. Inténtalo de nuevo en unos minutos.',
        statusCode: 502,
      );
      await confirmSend(tester);

      expect(find.text('No pudimos enviar el correo. Inténtalo de nuevo en unos minutos.'), findsOneWidget);
      repository.sendError = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(repository.sends, 2);
      expect(find.text('Confirmación $_reportId'), findsOneWidget);
    });

    testWidgets('already sent (409): clear message, no retry (CP-25)', (tester) async {
      await pumpPreview(tester);
      repository.sendError = const ApiException(
        code: 'ALREADY_SENT',
        message: 'Esta solicitud ya fue enviada.',
        statusCode: 409,
      );
      await confirmSend(tester);

      expect(find.text('Esta solicitud ya fue enviada.'), findsWidgets);
      expect(find.text('Reintentar'), findsNothing);
    });
  });
}
