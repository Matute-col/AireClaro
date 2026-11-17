import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../shared/widgets/states.dart';
import 'auth_controller.dart';

/// Shown while the app checks the saved session when it opens.
/// If there is no connection it offers «Reintentar» (no offline mode).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Only check once, when the app starts.
    if (ref.read(authControllerProvider).status == AuthStatus.checking) {
      Future.microtask(_restore);
    }
  }

  void _restore() => ref.read(authControllerProvider.notifier).restoreSession();

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: auth.status == AuthStatus.checkFailed
            ? ErrorState(message: auth.errorMessage ?? '', onRetry: _restore)
            : const LoadingState(message: 'Verificando tu sesión…'),
      ),
    );
  }
}
