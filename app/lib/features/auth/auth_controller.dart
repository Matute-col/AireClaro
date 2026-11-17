import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/token_storage.dart';
import 'auth_repository.dart';
import 'user.dart';

enum AuthStatus { authenticated, unauthenticated }

/// Session state: who is signed in (if anyone).
class AuthState {
  const AuthState._(this.status, {this.user});

  const AuthState.unauthenticated() : this._(AuthStatus.unauthenticated);

  const AuthState.authenticated(User user) : this._(AuthStatus.authenticated, user: user);

  final AuthStatus status;
  final User? user;

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

/// Opens and closes the session. The token lives only in secure storage;
/// the user stays in memory.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState.unauthenticated();

  /// Creates the account and opens the session (UC-01).
  /// Throws ApiException so the screen can show the error.
  Future<void> register(RegisterData data) async {
    final result = await ref.read(authRepositoryProvider).register(data);
    await ref.read(tokenStorageProvider).save(result.token);
    state = AuthState.authenticated(result.user);
  }

  /// Closes the session (UC-03).
  Future<void> logout() async {
    await ref.read(tokenStorageProvider).delete();
    state = const AuthState.unauthenticated();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
