import 'package:aireclaro/core/router.dart';
import 'package:aireclaro/features/auth/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

void main() {
  test('while checking, everything goes to /splash', () {
    expect(authRedirect(const AuthState.checking(), Routes.home), Routes.splash);
    expect(authRedirect(const AuthState.checkFailed('x'), Routes.welcome), Routes.splash);
    expect(authRedirect(const AuthState.checking(), Routes.splash), isNull);
  });

  test('without session only public screens are allowed', () {
    const out = AuthState.unauthenticated();
    expect(authRedirect(out, Routes.login), isNull);
    expect(authRedirect(out, Routes.register), isNull);
    expect(authRedirect(out, Routes.home), Routes.welcome);
    expect(authRedirect(out, Routes.splash), Routes.welcome);
  });

  test('expired session goes to the login', () {
    expect(
      authRedirect(const AuthState.unauthenticated(sessionExpired: true), Routes.home),
      Routes.login,
    );
  });

  test('with session, public screens go to /home', () {
    const signedIn = AuthState.authenticated(testUser);
    expect(authRedirect(signedIn, Routes.welcome), Routes.home);
    expect(authRedirect(signedIn, Routes.login), Routes.home);
    expect(authRedirect(signedIn, Routes.splash), Routes.home);
    expect(authRedirect(signedIn, Routes.home), isNull);
  });
}
