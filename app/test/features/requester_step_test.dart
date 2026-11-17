import 'package:aireclaro/core/token_storage.dart';
import 'package:aireclaro/features/auth/auth_controller.dart';
import 'package:aireclaro/features/auth/auth_repository.dart';
import 'package:aireclaro/features/report/report_draft.dart';
import 'package:aireclaro/features/report/requester_step_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fakes.dart';

void main() {
  late ProviderContainer container;

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
    ]);
    addTearDown(container.dispose);
    await container
        .read(authControllerProvider.notifier)
        .login(email: testUser.email, password: 'clave-segura');

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: RequesterStepScreen()),
    ));
    await tester.pump();
  }

  RequesterData requester() => container.read(reportDraftProvider).requester;
  Finder field(String label) => find.widgetWithText(TextFormField, label);
  bool reviewEnabled(WidgetTester tester) =>
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Revisar reporte')).onPressed !=
      null;

  testWidgets('fields are prefilled from the profile', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Estos datos se usan para generar tu solicitud.'), findsOneWidget);
    expect(find.text('Ana Prueba'), findsOneWidget);
    expect(find.text('0000000'), findsOneWidget);
    expect(find.text('ana@ejemplo.test'), findsOneWidget);
    expect(requester().name, 'Ana Prueba');
    expect(requester().docType, 'CC');
    expect(reviewEnabled(tester), isTrue);
  });

  testWidgets('edits are kept in the draft, not in the profile', (tester) async {
    await pumpScreen(tester);
    await tester.enterText(field('Correo'), 'otro@ejemplo.test');
    await tester.enterText(field('Teléfono (opcional)'), '3000000000');
    await tester.pump();

    expect(requester().email, 'otro@ejemplo.test');
    expect(requester().phone, '3000000000');
    expect(container.read(authControllerProvider).user?.email, testUser.email);
  });

  testWidgets('invalid data disables «Revisar reporte»', (tester) async {
    await pumpScreen(tester);
    await tester.enterText(field('Correo'), 'no-es-correo');
    await tester.pump();

    expect(find.text('Escribe un correo electrónico válido.'), findsOneWidget);
    expect(reviewEnabled(tester), isFalse);
  });

  testWidgets('coming back keeps the edited data (no new prefill)', (tester) async {
    await pumpScreen(tester);
    await tester.enterText(field('Nombre completo'), 'Ana María Prueba');
    await tester.pump();

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: RequesterStepScreen()),
    ));
    await tester.pump();
    expect(find.text('Ana María Prueba'), findsOneWidget);
  });
}
