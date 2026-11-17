import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/router.dart';
import '../../core/theme.dart';
import '../../shared/widgets/buttons.dart';

/// Screen 01 · Bienvenida: logo, name, tagline and the two entry buttons.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const _Logo(),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'AireClaro',
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  fontSize: 32,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Reporta vehículos contaminantes en el corredor Soacha–Bogotá',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge,
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Iniciar sesión',
                onPressed: () => context.push(Routes.login),
              ),
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                label: 'Crear cuenta',
                onPressed: () => context.push(Routes.register),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 112,
        height: 112,
        decoration: const BoxDecoration(
          color: AppColors.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.air, size: 64, color: AppColors.primary),
      ),
    );
  }
}
