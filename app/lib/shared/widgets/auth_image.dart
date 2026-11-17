import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../core/token_storage.dart';
import '../../features/auth/auth_controller.dart';

/// Evidence files are not public: they are served only to the owner with the token.
String mediaUrl(String reportId, String mediaId) =>
    '${AppConfig.apiBaseUrl}/reports/$reportId/media/$mediaId';

/// Current session token, re-read when the session changes.
final authTokenProvider = FutureProvider<String?>((ref) {
  ref.watch(authControllerProvider.select((s) => s.user?.id));
  return ref.watch(tokenStorageProvider).read();
});

/// Image from our API, requested with the `Authorization: Bearer` header.
class AuthNetworkImage extends ConsumerWidget {
  const AuthNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.placeholderIcon = Icons.image_outlined,
  });

  final String url;
  final BoxFit fit;

  /// Decode smaller for thumbnails (less memory).
  final int? cacheWidth;
  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placeholder = ColoredBox(
      color: AppColors.primaryContainer,
      child: Center(child: Icon(placeholderIcon, color: AppColors.primary)),
    );
    final token = ref.watch(authTokenProvider).value;
    if (token == null) return placeholder;

    return Image.network(
      url,
      headers: {'Authorization': 'Bearer $token'},
      fit: fit,
      cacheWidth: cacheWidth,
      loadingBuilder: (context, child, progress) => progress == null ? child : placeholder,
      errorBuilder: (context, error, stack) => placeholder,
    );
  }
}
