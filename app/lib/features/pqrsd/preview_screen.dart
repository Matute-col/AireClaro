import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/api_error.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/states.dart';
import '../report/reports_repository.dart';
import 'pdf_actions.dart';
import 'pqrsd_preview.dart';

final pqrsdPreviewProvider = FutureProvider.family<PqrsdPreview, String>(
  (ref, id) => ref.watch(reportsRepositoryProvider).getPqrsd(id),
);

/// Screen 10 · Vista previa de la solicitud (US-13, RF-08).
/// [justCreated]: opened right after «Generar solicitud» → shows «Continuar».
/// «Enviar a la autoridad» (US-21) and «Radicar en el portal oficial» (US-22) come next.
class PreviewScreen extends ConsumerWidget {
  const PreviewScreen({super.key, required this.reportId, this.justCreated = false});

  final String reportId;
  final bool justCreated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = ref.watch(pqrsdPreviewProvider(reportId));
    return Scaffold(
      appBar: AppBar(title: const Text('Vista previa de la solicitud')),
      body: preview.when(
        loading: () => const LoadingState(message: 'Generando la solicitud…'),
        error: (error, _) {
          final apiError = toApiException(error);
          if (apiError.statusCode == 404) {
            return const EmptyState(icon: Icons.search_off, title: 'No encontramos este reporte');
          }
          return ErrorState(
            message: apiError.message,
            onRetry: () => ref.invalidate(pqrsdPreviewProvider(reportId)),
          );
        },
        data: (data) => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text('Dirigida a', style: Theme.of(context).textTheme.labelLarge),
            Text(data.authority.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: SelectableText(data.text, style: const TextStyle(fontSize: 15, height: 1.4)),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PdfActions(reportId: reportId, plate: data.plate),
            if (justCreated) ...[
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: 'Continuar',
                onPressed: () => context.pushReplacement(Routes.reportDetail(reportId)),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
