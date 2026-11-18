import 'dart:async';

import 'package:aireclaro/core/api_error.dart';
import 'package:aireclaro/core/token_storage.dart';
import 'package:aireclaro/features/auth/auth_repository.dart';
import 'package:aireclaro/features/auth/user.dart';
import 'package:aireclaro/features/history/report_summary.dart';
import 'package:aireclaro/features/report/frame_extractor.dart';
import 'package:aireclaro/features/report/reports_repository.dart';
import 'package:aireclaro/shared/services/file_actions.dart';
import 'package:aireclaro/shared/services/url_opener.dart';

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

/// Reports repository with [total] fake reports, served in pages like the API.
class FakeReportsListRepository implements ReportsRepository {
  FakeReportsListRepository({this.total = 0});

  int total;
  ApiException? error;
  final requestedPages = <int>[];

  static ReportSummary summary(int i, {String status = 'generado'}) => ReportSummary(
        id: 'report-$i',
        plate: 'AAA${(100 + i).toString().padLeft(3, '0')}',
        vehicleType: 'bus',
        status: status,
        occurredAt: DateTime(2026, 11, 16, 9, 30).subtract(Duration(hours: i)),
        authorityName: 'Corporación Autónoma Regional de Cundinamarca (CAR)',
      );

  @override
  Future<ReportsPage> list({int page = 1, int limit = 20}) async {
    requestedPages.add(page);
    if (error != null) throw error!;
    final start = (page - 1) * limit;
    final end = (start + limit).clamp(0, total);
    final items = [for (var i = start; i < end; i++) summary(i, status: i == 1 ? 'enviado' : 'generado')];
    return ReportsPage(items: items, page: page, total: total);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Records what would be opened or shared instead of calling the phone.
class FakeFileActions implements FileActions {
  final opened = <String>[];
  final shared = <(String, String, String?)>[];
  String? openProblem;

  @override
  Future<String> tempPath(String fileName) async => '/tmp/$fileName';

  @override
  Future<String?> open(String path) async {
    opened.add(path);
    return openProblem;
  }

  @override
  Future<void> share(String path, {required String mimeType, String? subject}) async {
    shared.add((path, mimeType, subject));
  }
}

/// US-23 · Frame extractor without native plugins. [gate] keeps the extraction
/// «in progress» until it is completed; [fail] makes it throw.
class FakeFrameExtractor implements FrameExtractor {
  bool fail = false;
  Completer<void>? gate;
  final calls = <String>[];

  @override
  Future<List<String>> extract(String videoPath) async {
    calls.add(videoPath);
    if (gate != null) await gate!.future;
    if (fail) throw const FrameExtractionException('prueba');
    return [for (var i = 1; i <= 4; i++) '$videoPath-fotograma-$i.jpg'];
  }
}

/// US-22 · Records the pages that would be opened in the browser.
class FakeUrlOpener implements UrlOpener {
  final opened = <String>[];
  bool works = true;

  @override
  Future<bool> open(String url) async {
    opened.add(url);
    return works;
  }
}
