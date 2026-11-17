import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/router.dart';
import '../../core/theme.dart';
import '../../shared/widgets/buttons.dart';

/// Screen 01 · Bienvenida. Temporary version until US-04.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'AireClaro',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Iniciar sesión',
                onPressed: () => context.push(Routes.login),
              ),
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                label: 'Crear cuenta',
                onPressed: () => context.push(Routes.register),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
