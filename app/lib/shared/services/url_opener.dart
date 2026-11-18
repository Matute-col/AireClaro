import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a web page in the phone's browser (US-22). Replaced by a fake in tests.
class UrlOpener {
  /// True if the browser opened the page.
  Future<bool> open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https') return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

final urlOpenerProvider = Provider<UrlOpener>((ref) => UrlOpener());
