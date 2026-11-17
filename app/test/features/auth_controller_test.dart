import 'package:aireclaro/core/token_storage.dart';
import 'package:aireclaro/features/auth/auth_controller.dart';
import 'package:aireclaro/features/auth/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

void main() {
  late FakeAuthRepository repository;
  late MemoryTokenStorage storage;
  late ProviderContainer container;

  void setUpContainer({String? token}) {
    repository = FakeAuthRepository();
    storage = MemoryTokenStorage(token);
    container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      tokenStorageProvider.overrideWithValue(storage),
    ]);
    addTearDown(container.dispose);
  }

  AuthController controller() => container.read(authControllerProvider.notifier);
  AuthState state() => container.read(authControllerProvider);

  test('starts checking the session', () {
    setUpContainer();
    expect(state().status, AuthStatus.checking);
  });

  test('without a saved token the user is signed out (no API call)', () async {
    setUpContainer();
    await controller().restoreSession();
    expect(state().status, AuthStatus.unauthenticated);
    expect(repository.meCalls, 0);
  });

  test('a saved valid token restores the session', () async {
    setUpContainer(token: 'saved');
    await controller().restoreSession();
    expect(state().isAuthenticated, isTrue);
    expect(state().user?.email, testUser.email);
  });

  test('a rejected token (401) is deleted', () async {
    setUpContainer(token: 'expired');
    repository.error = unauthorizedError;
    await controller().restoreSession();
    expect(state().status, AuthStatus.unauthenticated);
    expect(storage.token, isNull);
  });

  test('without connection the token is kept and retry is offered', () async {
    setUpContainer(token: 'saved');
    repository.error = networkError;
    await controller().restoreSession();
    expect(state().status, AuthStatus.checkFailed);
    expect(state().errorMessage, contains('No pudimos conectar'));
    expect(storage.token, 'saved');
  });

  test('login saves the token and logout deletes it', () async {
    setUpContainer();
    await controller().login(email: 'ana@ejemplo.test', password: 'clave-segura');
    expect(state().isAuthenticated, isTrue);
    expect(storage.token, 'test-token');

    await controller().logout();
    expect(state().status, AuthStatus.unauthenticated);
    expect(storage.token, isNull);
  });

  test('a 401 while signed in closes the session as expired', () async {
    setUpContainer();
    await controller().login(email: 'ana@ejemplo.test', password: 'clave-segura');
    await controller().sessionExpired();
    expect(state().status, AuthStatus.unauthenticated);
    expect(state().sessionExpired, isTrue);
    expect(storage.token, isNull);
  });
}
