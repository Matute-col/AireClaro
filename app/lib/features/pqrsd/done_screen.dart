import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/api_error.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/states.dart';
import '../history/report_detail.dart';
import '../history/report_detail_screen.dart';
import 'pqrsd_preview.dart';

/// Screen 11 · Confirmación (US-14 / US-21). The title depends on the case:
/// sent by email, marked as sent by hand, or only generated.
class DoneScreen extends ConsumerWidget {
  const DoneScreen({super.key, required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(reportDetailProvider(reportId));
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmación'), automaticallyImplyLeading: false),
      body: detail.when(
        loading: () => const LoadingState(),
        error: (error, _) => ErrorState(
          message: toApiException(error).message,
          onRetry: () => ref.invalidate(reportDetailProvider(reportId)),
        ),
        data: (report) => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _Header(report: report),
            const SizedBox(height: AppSpacing.lg),
            const _FollowUp(),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(label: 'Ver mis reportes', onPressed: () => context.go(Routes.reports)),
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(label: 'Volver al inicio', onPressed: () => context.go(Routes.home)),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.report});

  final ReportDetail report;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final byEmail = report.status == 'enviado' && report.sentVia == 'email';
    final byHand = report.status == 'enviado' && report.sentVia != 'email';
    final title = byEmail
        ? 'Solicitud enviada a ${report.authority.name}'
        : byHand
            ? 'Reporte marcado como enviado'
            : 'Reporte generado';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          report.status == 'enviado' ? Icons.mark_email_read_outlined : Icons.check_circle_outline,
          size: 72,
          color: AppColors.success,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(title, textAlign: TextAlign.center, style: textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Reporte n.º ${shortReportId(report.id)} · placa ${report.plate}',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        if (byEmail && report.sendMode == 'test') ...[
          const MessageBanner(
            message: 'Modo de prueba: el correo llegó al buzón de prueba, no a la autoridad.',
            isError: false,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (byEmail)
          Text(
            'Revisa la copia que llegó a ${report.requesterEmail}. La respuesta de la entidad '
            'llegará a ese correo.',
            textAlign: TextAlign.center,
          )
        else if (!byHand)
          const Text(
            'Puedes enviarla por correo desde la vista previa, radicarla en el portal oficial o '
            'compartir el PDF.',
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}

/// «¿Cómo hacer seguimiento?» (docs/06, text only; Ley 1755 de 2015).
class _FollowUp extends StatelessWidget {
  const _FollowUp();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Cómo hacer seguimiento?', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              '• La entidad debe responder al correo del peticionario.\n'
              '• El término general de respuesta es de 15 días siguientes a la recepción '
              '(Ley 1755 de 2015).\n'
              '• Si la entidad no es la competente, debe remitir la solicitud a la que '
              'corresponda e informarte.\n'
              '• Si la enviaste por correo, revisa la copia que recibiste.',
            ),
          ],
        ),
      ),
    );
  }
}
