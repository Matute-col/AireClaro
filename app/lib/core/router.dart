import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/home/home_screen.dart';
import '../features/profile/edit_profile_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/report/evidence_step_screen.dart';
import '../features/report/location_step_screen.dart';
import '../features/report/requester_step_screen.dart';
import '../features/report/vehicle_step_screen.dart';
import '../features/welcome/welcome_screen.dart';
import '../shared/widgets/coming_soon_screen.dart';
import '../shared/widgets/main_shell.dart';

/// Route paths from docs/06 (plus /splash, shown while the session is checked).
class Routes {
  Routes._();

  static const splash = '/splash';
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const map = '/map';
  static const reports = '/reports';
  static const info = '/info';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';

  // New report flow (outside the shell: no bottom bar).
  static const reportEvidence = '/report/evidence';
  static const reportVehicle = '/report/vehicle';
  static const reportLocation = '/report/location';
  static const reportRequester = '/report/requester';
  static const reportReview = '/report/review';

  /// Screens that are only for people without a session.
  static const public = {welcome, login, register};
}

/// Decides where to go based on the session (docs/06):
/// - while checking the saved token → /splash;
/// - without session → only public screens; otherwise /welcome
///   (or /login with «Tu sesión expiró» if the token expired);
/// - with session and on a public screen or /splash → /home.
String? authRedirect(AuthState auth, String location) {
  switch (auth.status) {
    case AuthStatus.checking:
    case AuthStatus.checkFailed:
      return location == Routes.splash ? null : Routes.splash;
    case AuthStatus.unauthenticated:
      if (Routes.public.contains(location)) return null;
      return auth.sessionExpired ? Routes.login : Routes.welcome;
    case AuthStatus.authenticated:
      if (Routes.public.contains(location) || location == Routes.splash) return Routes.home;
      return null;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  // go_router re-runs the redirect each time this notifier changes,
  // so we bump it whenever the session changes.
  final sessionChanged = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => sessionChanged.value++);
  ref.onDispose(sessionChanged.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: sessionChanged,
    redirect: (context, state) =>
        authRedirect(ref.read(authControllerProvider), state.matchedLocation),
    routes: [
      GoRoute(path: Routes.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: Routes.welcome, builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: Routes.login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: Routes.register, builder: (context, state) => const RegisterScreen()),

      // The four main screens share the bottom bar.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.home, builder: (context, state) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.map,
              builder: (context, state) =>
                  const ComingSoonScreen(title: 'Mapa de reportes', icon: Icons.map_outlined),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.reports,
              builder: (context, state) =>
                  const ComingSoonScreen(title: 'Mis reportes', icon: Icons.list_alt),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.info,
              builder: (context, state) =>
                  const ComingSoonScreen(title: '¿Cómo funciona?', icon: Icons.help_outline),
            ),
          ]),
        ],
      ),

      // Outside the shell: no bottom bar.
      GoRoute(
        path: Routes.reportEvidence,
        builder: (context, state) => const EvidenceStepScreen(),
      ),
      GoRoute(
        path: Routes.reportVehicle,
        builder: (context, state) => const VehicleStepScreen(),
      ),
      GoRoute(
        path: Routes.reportLocation,
        builder: (context, state) => const LocationStepScreen(),
      ),
      GoRoute(
        path: Routes.reportRequester,
        builder: (context, state) => const RequesterStepScreen(),
      ),
      // Review (US-09).
      GoRoute(
        path: Routes.reportReview,
        builder: (context, state) =>
            const ComingSoonScreen(title: 'Revisión', icon: Icons.fact_check_outlined),
      ),
      GoRoute(
        path: Routes.profile,
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(path: 'edit', builder: (context, state) => const EditProfileScreen()),
        ],
      ),
    ],
  );
});
