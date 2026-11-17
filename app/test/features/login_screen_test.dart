import 'package:aireclaro/core/api_error.dart';
import 'package:aireclaro/core/token_storage.dart';
import 'package:aireclaro/features/auth/auth_controller.dart';
import 'package:aireclaro/features/auth/auth_repository.dart';
import 'package:aireclaro/features/auth/login_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fakes.dart';

void main() {
  late FakeAuthRepository repository;
  late ProviderContainer container;

  Future<void> pumpScreen(WidgetTester tester) async {
    repository = FakeAuthRepository();
    container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: LoginScreen()),
    ));
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);
  FilledButton button(WidgetTester tester) =>
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Ingresar'));

  testWidgets('login button is disabled with empty fields or an invalid email', (tester) async {
    await pumpScreen(tester);
    expect(button(tester).onPressed, isNull);

    await tester.enterText(field('Correo electrónico'), 'no-es-correo');
    await tester.enterText(field('Contraseña'), 'clave-segura');
    await tester.pump();
    expect(button(tester).onPressed, isNull);

    await tester.enterText(field('Correo electrónico'), 'ana@ejemplo.test');
    await tester.pump();
    expect(button(tester).onPressed, isNotNull);
  });

  testWidgets('wrong credentials show the generic message', (tester) async {
    await pumpScreen(tester);
    repository.error = const ApiException(
      code: 'INVALID_CREDENTIALS',
      message: 'Correo o contraseña incorrectos.',
      statusCode: 401,
    );
    await tester.enterText(field('Correo electrónico'), 'ana@ejemplo.test');
    await tester.enterText(field('Contraseña'), 'clave-mala');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Ingresar'));
    await tester.pumpAndSettle();

    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
    expect(container.read(authControllerProvider).isAuthenticated, isFalse);
  });

  testWidgets('valid credentials open the session', (tester) async {
    await pumpScreen(tester);
    await tester.enterText(field('Correo electrónico'), ' Ana@Ejemplo.test ');
    await tester.enterText(field('Contraseña'), 'clave-segura');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Ingresar'));
    await tester.pumpAndSettle();

    expect(repository.lastLoginEmail, 'ana@ejemplo.test');
    expect(container.read(authControllerProvider).isAuthenticated, isTrue);
  });

  testWidgets('shows the expired-session message after a 401', (tester) async {
    await pumpScreen(tester);
    final controller = container.read(authControllerProvider.notifier);
    await controller.login(email: 'ana@ejemplo.test', password: 'clave-segura');
    await controller.sessionExpired();
    await tester.pump();

    expect(find.text('Tu sesión expiró. Inicia sesión de nuevo.'), findsOneWidget);
  });
}
