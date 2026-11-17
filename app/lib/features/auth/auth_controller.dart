import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_error.dart';
import '../../core/token_storage.dart';
import 'auth_repository.dart';
import 'user.dart';

enum AuthStatus {
  /// Opening the app: checking the saved token with the API.
  checking,

  /// The saved token could not be checked (no connection, server down).
  checkFailed,
  authenticated,
  unauthenticated,
}

/// Session state: who is signed in (if anyone).
class AuthState {
  const AuthState._(this.status, {this.user, this.sessionExpired = false, this.errorMessage});

  const AuthState.checking() : this._(AuthStatus.checking);

  const AuthState.checkFailed(String message)
      : this._(AuthStatus.checkFailed, errorMessage: message);

  const AuthState.authenticated(User user) : this._(AuthStatus.authenticated, user: user);

  /// [sessionExpired] is true when the API rejected the token while using the app.
  const AuthState.unauthenticated({bool sessionExpired = false})
      : this._(AuthStatus.unauthenticated, sessionExpired: sessionExpired);

  final AuthStatus status;
  final User? user;
  final bool sessionExpired;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

/// Opens, restores and closes the session. The token lives only in secure
/// storage; the user stays in memory.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState.checking();

  /// Called when the app opens (persistent session, UC-02):
  /// a saved and still valid token goes straight to Inicio.
  Future<void> restoreSession() async {
    state = const AuthState.checking();
    final storage = ref.read(tokenStorageProvider);
    final token = await storage.read();
    if (token == null || token.isEmpty) {
      state = const AuthState.unauthenticated();
      return;
    }
    try {
      final user = await ref.read(authRepositoryProvider).me();
      state = AuthState.authenticated(user);
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        // Expired or invalid token: forget it and start over.
        await storage.delete();
        state = const AuthState.unauthenticated();
      } else {
        // Keep the token: it may still be valid when the connection comes back.
        state = AuthState.checkFailed(error.message);
      }
    }
  }

  /// Creates the account and opens the session (UC-01).
  /// Throws ApiException so the screen can show the error.
  Future<void> register(RegisterData data) async {
    final result = await ref.read(authRepositoryProvider).register(data);
    await _open(result);
  }

  /// Signs in with email and password (UC-02). Throws ApiException.
  Future<void> login({required String email, required String password}) async {
    final result = await ref.read(authRepositoryProvider).login(email: email, password: password);
    await _open(result);
  }

  /// Replaces the user after editing the profile (US-03).
  void updateUser(User user) {
    if (state.isAuthenticated) state = AuthState.authenticated(user);
  }

  /// Closes the session (UC-03).
  Future<void> logout() async {
    await ref.read(tokenStorageProvider).delete();
    state = const AuthState.unauthenticated();
  }

  /// The API answered 401 to a request with a token (docs/06, screen 17).
  Future<void> sessionExpired() async {
    // While checking at startup, restoreSession handles the 401 itself.
    if (!state.isAuthenticated) return;
    await ref.read(tokenStorageProvider).delete();
    state = const AuthState.unauthenticated(sessionExpired: true);
  }

  Future<void> _open(AuthResult result) async {
    await ref.read(tokenStorageProvider).save(result.token);
    state = AuthState.authenticated(result.user);
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
