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

const networkError = ApiException(
  code: ApiException.networkCode,
  message: 'No pudimos conectar con el servidor. Revisa tu conexión e inténtalo de nuevo.',
);

const unauthorizedError = ApiException(
  code: 'UNAUTHORIZED',
  message: 'Tu sesión no es válida. Inicia sesión de nuevo.',
  statusCode: 401,
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
  String? lastLoginEmail;
  int meCalls = 0;

  @override
  Future<AuthResult> register(RegisterData data) async {
    lastRegister = data;
    if (error != null) throw error!;
    return const AuthResult(token: 'test-token', user: testUser);
  }

  @override
  Future<AuthResult> login({required String email, required String password}) async {
    lastLoginEmail = email;
    if (error != null) throw error!;
    return const AuthResult(token: 'test-token', user: testUser);
  }

  @override
  Future<User> me() async {
    meCalls++;
    if (error != null) throw error!;
    return testUser;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
