import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/router.dart';
import '../../core/theme.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/privacy_policy_dialog.dart';
import '../auth/auth_controller.dart';

/// Screen 16 · Perfil (UC-03, UC-04, RF-13).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Quieres cerrar tu sesión en este celular?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      // The router goes to Bienvenida when the session closes.
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    if (user == null) return const Scaffold();

    final phone = user.phone;
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Card(
              child: Column(
                children: [
                  _InfoTile(icon: Icons.person_outline, label: 'Nombre', value: user.fullName),
                  _InfoTile(
                    icon: Icons.badge_outlined,
                    label: 'Documento',
                    value: '${user.docType} ${user.docNumber}',
                  ),
                  _InfoTile(icon: Icons.email_outlined, label: 'Correo', value: user.email),
                  _InfoTile(
                    icon: Icons.phone_outlined,
                    label: 'Teléfono',
                    value: (phone == null || phone.isEmpty) ? 'No registrado' : phone,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Editar',
              icon: Icons.edit_outlined,
              onPressed: () => context.push(Routes.editProfile),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => showPrivacyPolicyDialog(context),
              child: const Text('Política de tratamiento de datos'),
            ),
            const SizedBox(height: AppSpacing.lg),
            SecondaryButton(
              label: 'Cerrar sesión',
              onPressed: () => _confirmLogout(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: Theme.of(context).textTheme.labelLarge),
      subtitle: Text(value, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}
