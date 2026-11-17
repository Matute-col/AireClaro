import 'package:aireclaro/core/api_error.dart';
import 'package:aireclaro/core/token_storage.dart';
import 'package:aireclaro/features/auth/auth_controller.dart';
import 'package:aireclaro/features/auth/auth_repository.dart';
import 'package:aireclaro/features/auth/register_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fakes.dart';

void main() {
  late FakeAuthRepository repository;
  late MemoryTokenStorage storage;
  late ProviderContainer container;

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    repository = FakeAuthRepository();
    storage = MemoryTokenStorage();
    container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      tokenStorageProvider.overrideWithValue(storage),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: RegisterScreen()),
    ));
  }

  Future<void> fillValidForm(WidgetTester tester, {String confirm = 'clave-segura'}) async {
    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre completo'), 'Ana Prueba');
    await tester.tap(find.text('Tipo de documento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cédula de ciudadanía (CC)').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Número de documento'), '0000000');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo electrónico'), 'ana@ejemplo.test');
    await tester.enterText(find.widgetWithText(TextFormField, 'Contraseña'), 'clave-segura');
    await tester.enterText(find.widgetWithText(TextFormField, 'Confirmar contraseña'), confirm);
    await tester.pump();
  }

  FilledButton submitButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Crear cuenta'));

  testWidgets('button stays disabled until the consent box is checked', (tester) async {
    await pumpScreen(tester);
    await fillValidForm(tester);
    expect(submitButton(tester).onPressed, isNull);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(submitButton(tester).onPressed, isNotNull);
  });

  testWidgets('button stays disabled when passwords do not match', (tester) async {
    await pumpScreen(tester);
    await fillValidForm(tester, confirm: 'otra-clave');
    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    expect(submitButton(tester).onPressed, isNull);
    expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
  });

  testWidgets('successful registration opens the session and saves the token', (tester) async {
    await pumpScreen(tester);
    await fillValidForm(tester);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
    await tester.pumpAndSettle();

    expect(repository.lastRegister?.email, 'ana@ejemplo.test');
    expect(storage.token, 'test-token');
    expect(container.read(authControllerProvider).isAuthenticated, isTrue);
  });

  testWidgets('duplicated email is shown under the email field', (tester) async {
    await pumpScreen(tester);
    repository.error = const ApiException(
      code: 'EMAIL_TAKEN',
      message: 'Este correo ya está registrado.',
      statusCode: 409,
      fieldErrors: {'email': 'Este correo ya está registrado.'},
    );
    await fillValidForm(tester);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('Este correo ya está registrado.'), findsOneWidget);
    expect(storage.token, isNull);
  });
}
