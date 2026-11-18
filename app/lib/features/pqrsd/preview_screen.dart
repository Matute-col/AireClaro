import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/api_error.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/states.dart';
import '../history/report_detail_screen.dart';
import '../history/reports_list_controller.dart';
import '../report/reports_repository.dart';
import 'pdf_actions.dart';
import 'pqrsd_preview.dart';

final pqrsdPreviewProvider = FutureProvider.family<PqrsdPreview, String>(
  (ref, id) => ref.watch(reportsRepositoryProvider).getPqrsd(id),
);

/// Screen 10 · Vista previa de la solicitud (US-13, US-21, RF-08).
/// Buttons in the order of docs/06: «Enviar a la autoridad» (only with a verified email
/// and not sent yet), «Descargar PDF» / «Compartir», and «Continuar» right after creating.
class PreviewScreen extends ConsumerStatefulWidget {
  const PreviewScreen({super.key, required this.reportId, this.justCreated = false});

  final String reportId;
  final bool justCreated;

  @override
  ConsumerState<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends ConsumerState<PreviewScreen> {
  bool _sending = false;

  String get _id => widget.reportId;

  void _message(String text, {VoidCallback? retry}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text),
        action: retry == null ? null : SnackBarAction(label: 'Reintentar', onPressed: retry),
      ));
  }

  /// RF-17: every sending needs the user's explicit confirmation (RNF-04).
  Future<bool> _confirm(PqrsdPreview data) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enviar a la autoridad'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Se enviará tu solicitud con el PDF y la evidencia a ${data.authority.name}. '
              'Recibirás una copia en ${data.requesterEmail} y la respuesta llegará a ese correo.',
            ),
            if (data.mailMode == 'test') ...[
              const SizedBox(height: AppSpacing.md),
              const MessageBanner(
                message: 'Modo de prueba: el correo va a un buzón de prueba, no a la autoridad.',
                isError: false,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Enviar')),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _send(PqrsdPreview data) async {
    if (_sending || !await _confirm(data)) return;
    await _doSend();
  }

  Future<void> _doSend() async {
    setState(() => _sending = true);
    try {
      await ref.read(reportsRepositoryProvider).sendReport(_id);
      _refreshReport();
      if (mounted) context.pushReplacement(Routes.reportDone(_id));
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 409) _refreshReport(); // already sent: show the new status
      final canRetry = error.isNetworkError || error.statusCode == 502;
      _message(error.message, retry: canRetry ? _doSend : null);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// The status changed: preview, detail and list must show it.
  void _refreshReport() {
    ref.invalidate(pqrsdPreviewProvider(_id));
    ref.invalidate(reportDetailProvider(_id));
    ref.invalidate(reportsListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final preview = ref.watch(pqrsdPreviewProvider(_id));
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
            onRetry: () => ref.invalidate(pqrsdPreviewProvider(_id)),
          );
        },
        data: (data) => LoadingOverlay(
          loading: _sending,
          message: 'Enviando la solicitud…',
          child: _body(data),
        ),
      ),
    );
  }

  Widget _body(PqrsdPreview data) {
    final textTheme = Theme.of(context).textTheme;
    final canSend = data.authority.canEmail && data.status == 'generado' && data.mailMode != 'off';
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text('Dirigida a', style: textTheme.labelLarge),
        Text(data.authority.name, style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        if (data.status == 'enviado') ...[
          const MessageBanner(message: 'Esta solicitud ya fue enviada.', isError: false),
          const SizedBox(height: AppSpacing.md),
        ],
        if (canSend) ...[
          PrimaryButton(
            label: 'Enviar a la autoridad',
            icon: Icons.send_outlined,
            onPressed: _sending ? null : () => _send(data),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        PdfActions(reportId: _id, plate: data.plate),
        if (widget.justCreated) ...[
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: 'Continuar',
            onPressed: () => context.pushReplacement(Routes.reportDone(_id)),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text('Texto de la solicitud', style: textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SelectableText(data.text, style: const TextStyle(fontSize: 15, height: 1.4)),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
