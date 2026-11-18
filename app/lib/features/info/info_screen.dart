import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/api_error.dart';
import '../../core/theme.dart';
import '../../shared/widgets/privacy_policy_dialog.dart';
import '../../shared/widgets/states.dart';
import '../report/authorities_repository.dart';

/// Screen 15 · Información: ¿Cómo funciona? (US-16, RF-14, RNF-08).
class InfoScreen extends ConsumerWidget {
  const InfoScreen({super.key});

  static const _steps = [
    (
      Icons.photo_camera_outlined,
      'Captura la evidencia',
      'Toma fotos o graba un video corto donde se vea la placa y el humo.',
    ),
    (
      Icons.edit_note,
      'Completa los datos',
      'Tipo de vehículo, placa, color del humo, ubicación y tus datos de contacto.',
    ),
    (
      Icons.description_outlined,
      'Genera la solicitud',
      'AireClaro arma una petición formal (PQRSD) en PDF con tu evidencia.',
    ),
    (
      Icons.send_outlined,
      'Preséntala a la autoridad',
      'Envíala por correo desde la app, radícala en el portal oficial o compártela.',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final authorities = ref.watch(authoritiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('¿Cómo funciona?')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            'Reporta vehículos contaminantes en el corredor Soacha–Bogotá',
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          for (final (i, (icon, title, body)) in _steps.indexed)
            Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryContainer,
                  child: Icon(icon, color: AppColors.primary),
                ),
                title: Text('${i + 1}. $title'),
                subtitle: Text(body),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Text('Autoridades a las que se dirige', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          authorities.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => MessageBanner(
              message: toApiException(error).message,
              actionLabel: 'Reintentar',
              onAction: () => ref.invalidate(authoritiesProvider),
            ),
            data: (list) => Column(
              children: [
                for (final authority in list)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.account_balance_outlined, color: AppColors.primary),
                    title: Text(authority.name),
                    subtitle: Text(_howItReceives(authority)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'La app sugiere la autoridad según el lugar: Bogotá → Secretaría Distrital de Ambiente; '
            'Soacha u otro municipio de Cundinamarca → CAR. Siempre puedes cambiarla antes de '
            'generar la solicitud.',
          ),
          const SizedBox(height: AppSpacing.lg),
          const MessageBanner(
            message: 'AireClaro no mide emisiones ni impone sanciones. Genera una solicitud con la '
                'evidencia que tú aportas.',
            isError: false,
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton.icon(
            onPressed: () => showPrivacyPolicyDialog(context),
            icon: const Icon(Icons.privacy_tip_outlined),
            label: const Text('Política de tratamiento de datos'),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  static String _howItReceives(Authority authority) {
    if (authority.canEmail && authority.portalUrl != null) {
      return 'Recibe la solicitud por correo desde la app o en su portal oficial.';
    }
    if (authority.canEmail) return 'Recibe la solicitud por correo desde la app.';
    if (authority.portalUrl != null) return 'Se radica en su portal oficial.';
    return 'Comparte el PDF por el medio que prefieras.';
  }
}
