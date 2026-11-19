import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/router.dart';
import '../../core/theme.dart';
import '../auth/auth_controller.dart';
import '../history/reports_list_controller.dart';
import '../report/report_draft.dart';

/// Screen 04 · Inicio: greeting, «Nuevo reporte» and shortcuts.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hola, ${user?.firstName ?? ''}',
          style: textTheme.headlineSmall,
        ),
        actions: [
          IconButton(
            tooltip: 'Perfil',
            iconSize: 32,
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push(Routes.profile),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          SizedBox(
            height: 72,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.newReport,
                foregroundColor: AppColors.onHomeCard,
              ),
              onPressed: () {
                ref.read(reportDraftProvider.notifier).reset();
                context.push(Routes.reportEvidence);
              },
              icon: const Icon(Icons.add_a_photo_outlined, size: 28),
              label: Text(
                'Nuevo reporte',
                style: textTheme.titleLarge?.copyWith(
                  color: AppColors.onHomeCard,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ShortcutCard(
            icon: Icons.list_alt,
            title: 'Mis reportes',
            color: AppColors.myReports,
            foreground: AppColors.onHomeCard,
            subtitle: ref
                .watch(reportsCountProvider)
                .when(
                  data: (n) => n == 1 ? '1 reporte' : '$n reportes',
                  loading: () => 'Cargando…',
                  error: (_, _) => 'Consulta tus reportes y su estado',
                ),
            onTap: () => context.go(Routes.reports),
          ),
          _ShortcutCard(
            icon: Icons.map_outlined,
            title: 'Mapa de reportes',
            subtitle: 'Mira dónde se ha reportado',
            onTap: () => context.go(Routes.map),
          ),
          _ShortcutCard(
            icon: Icons.help_outline,
            title: '¿Cómo funciona?',
            subtitle: 'Pasos y autoridades a las que se dirige',
            onTap: () => context.go(Routes.info),
          ),
        ],
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color,
    this.foreground,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Optional card and text colors (from AppColors), e.g. «Mis reportes».
  final Color? color;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        textColor: foreground,
        iconColor: foreground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryContainer,
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: foreground),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
