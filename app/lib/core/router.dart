import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/register_screen.dart';
import '../features/home/home_screen.dart';
import '../features/welcome/welcome_screen.dart';

/// Route paths from docs/06.
class Routes {
  Routes._();

  static const welcome = '/welcome';
  static const register = '/register';
  static const home = '/home';

  /// Screens that are only for people without a session.
  static const public = {welcome, register};
}

/// Decides where to go based on the session (docs/06):
/// - without session → only public screens, otherwise /welcome;
/// - with session and on a public screen → /home.
String? authRedirect(AuthState auth, String location) {
  final isPublic = Routes.public.contains(location);
  if (!auth.isAuthenticated) return isPublic ? null : Routes.welcome;
  if (isPublic) return Routes.home;
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  // go_router re-runs the redirect each time this notifier changes,
  // so we bump it whenever the session changes.
  final sessionChanged = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => sessionChanged.value++);
  ref.onDispose(sessionChanged.dispose);

  return GoRouter(
    initialLocation: Routes.welcome,
    refreshListenable: sessionChanged,
    redirect: (context, state) =>
        authRedirect(ref.read(authControllerProvider), state.matchedLocation),
    routes: [
      GoRoute(path: Routes.welcome, builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: Routes.register, builder: (context, state) => const RegisterScreen()),
      GoRoute(path: Routes.home, builder: (context, state) => const HomeScreen()),
    ],
  );
});
