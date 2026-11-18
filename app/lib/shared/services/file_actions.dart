import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Opens and shares files with the phone's apps. Replaced by a fake in tests.
class FileActions {
  /// Path inside the app's temporary folder (cleared by Android when space is needed).
  Future<String> tempPath(String fileName) async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/$fileName';
  }

  /// Opens the file with the default app. Returns null if it worked, or a message.
  Future<String?> open(String path) async {
    final result = await OpenFilex.open(path);
    return switch (result.type) {
      ResultType.done => null,
      ResultType.noAppToOpen => 'No hay una app en el teléfono para abrir este archivo.',
      _ => 'No pudimos abrir el archivo. Inténtalo de nuevo.',
    };
  }

  /// Opens the phone's share menu (email, WhatsApp, Drive…) with the file.
  Future<void> share(String path, {required String mimeType, String? subject}) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(path, mimeType: mimeType)], subject: subject, text: subject),
    );
  }
}

final fileActionsProvider = Provider<FileActions>((ref) => FileActions());
