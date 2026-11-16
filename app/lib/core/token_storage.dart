import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores only the session token (JWT), encrypted by Android's Keystore.
/// No passwords or personal data are stored on the phone.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  final FlutterSecureStorage _storage;

  Future<String?> read() => _storage.read(key: _tokenKey);

  Future<void> save(String token) => _storage.write(key: _tokenKey, value: token);

  Future<void> delete() => _storage.delete(key: _tokenKey);
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());
