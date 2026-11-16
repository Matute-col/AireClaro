import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Route paths from docs/06.
class Routes {
  Routes._();

  static const welcome = '/welcome';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.welcome,
    routes: [
      GoRoute(
        path: Routes.welcome,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('AireClaro')),
        ),
      ),
    ],
  );
});
