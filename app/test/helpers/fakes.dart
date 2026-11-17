import 'package:aireclaro/core/api_error.dart';
import 'package:aireclaro/core/token_storage.dart';
import 'package:aireclaro/features/auth/auth_repository.dart';
import 'package:aireclaro/features/auth/user.dart';

const testUser = User(
  id: '1',
  fullName: 'Ana Prueba',
  docType: 'CC',
  docNumber: '0000000',
  email: 'ana@ejemplo.test',
);

/// Keeps the token in memory instead of the phone's secure storage.
class MemoryTokenStorage implements TokenStorage {
  MemoryTokenStorage([this.token]);

  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> save(String value) async => token = value;

  @override
  Future<void> delete() async => token = null;
}

/// Auth repository that answers without network. Set [error] to make calls fail.
class FakeAuthRepository implements AuthRepository {
  ApiException? error;
  RegisterData? lastRegister;

  @override
  Future<AuthResult> register(RegisterData data) async {
    lastRegister = data;
    if (error != null) throw error!;
    return const AuthResult(token: 'test-token', user: testUser);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

