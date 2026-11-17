import 'package:aireclaro/core/api_error.dart';
import 'package:aireclaro/core/token_storage.dart';
import 'package:aireclaro/features/auth/auth_controller.dart';
import 'package:aireclaro/features/auth/auth_repository.dart';
import 'package:aireclaro/features/auth/user.dart';
import 'package:aireclaro/features/profile/edit_profile_screen.dart';
import 'package:aireclaro/features/profile/profile_repository.dart';
import 'package:aireclaro/features/profile/profile_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fakes.dart';

class _FakeProfileRepository implements ProfileRepository {
  ApiException? error;
  ProfileData? lastUpdate;

  @override
  Future<User> update(ProfileData data) async {
    lastUpdate = data;
    if (error != null) throw error!;
    return User(
      id: testUser.id,
      fullName: data.fullName,
      docType: data.docType,
      docNumber: data.docNumber,
      email: testUser.email,
      phone: data.phone,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeProfileRepository profileRepository;
  late MemoryTokenStorage storage;
  late ProviderContainer container;

  Future<void> pumpSignedIn(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    profileRepository = _FakeProfileRepository();
    storage = MemoryTokenStorage();
    container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      profileRepositoryProvider.overrideWithValue(profileRepository),
      tokenStorageProvider.overrideWithValue(storage),
    ]);
    addTearDown(container.dispose);
    await container
        .read(authControllerProvider.notifier)
        .login(email: testUser.email, password: 'clave-segura');

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: screen),
    ));
  }

  testWidgets('profile shows the user data', (tester) async {
    await pumpSignedIn(tester, const ProfileScreen());
    expect(find.text('Ana Prueba'), findsOneWidget);
    expect(find.text('CC 0000000'), findsOneWidget);
    expect(find.text('ana@ejemplo.test'), findsOneWidget);
    expect(find.text('No registrado'), findsOneWidget);
  });

  testWidgets('logout asks for confirmation and deletes the token', (tester) async {
    await pumpSignedIn(tester, const ProfileScreen());
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cerrar sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(container.read(authControllerProvider).isAuthenticated, isFalse);
    expect(storage.token, isNull);
  });

  testWidgets('email cannot be edited', (tester) async {
    await pumpSignedIn(tester, const EditProfileScreen());
    final email = tester.widget<TextField>(
      find.descendant(of: find.byKey(const Key('email-readonly')), matching: find.byType(TextField)),
    );
    expect(email.enabled, isFalse);
  });

  testWidgets('saving updates the user in the session', (tester) async {
    await pumpSignedIn(tester, const EditProfileScreen());
    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre completo'), 'Ana María Prueba');
    await tester.enterText(find.widgetWithText(TextFormField, 'Teléfono (opcional)'), '300 000 0000');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar cambios'));
    await tester.pumpAndSettle();

    expect(profileRepository.lastUpdate?.phone, '3000000000');
    expect(container.read(authControllerProvider).user?.fullName, 'Ana María Prueba');
  });

  testWidgets('API field errors are shown under the field', (tester) async {
    await pumpSignedIn(tester, const EditProfileScreen());
    profileRepository.error = const ApiException(
      code: 'VALIDATION_ERROR',
      message: 'Revisa los datos ingresados.',
      statusCode: 400,
      fieldErrors: {'doc_number': 'Número de documento no válido.'},
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar cambios'));
    await tester.pumpAndSettle();

    expect(find.text('Número de documento no válido.'), findsOneWidget);
    expect(container.read(authControllerProvider).user?.fullName, testUser.fullName);
  });
}
