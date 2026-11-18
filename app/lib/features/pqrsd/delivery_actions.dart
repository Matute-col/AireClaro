import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/api_error.dart';
import '../../shared/services/url_opener.dart';
import '../history/report_detail_screen.dart';
import '../history/reports_list_controller.dart';
import '../report/reports_repository.dart';
import 'preview_screen.dart';

/// US-22 · «Radicar en el portal oficial»: opens the authority's official page in the
/// browser. The citizen downloads the PDF, attaches it there and comes back to mark the
/// report as sent. Shown for every authority with a portal_url (Mateo, 17-nov-2026).
class PortalButton extends ConsumerWidget {
  const PortalButton({super.key, required this.portalUrl});

  final String portalUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.open_in_new),
      label: const Text('Radicar en el portal oficial'),
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        final opened = await ref.read(urlOpenerProvider).open(portalUrl);
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(
              opened
                  ? 'Adjunta allí el PDF de la solicitud. Al terminar, vuelve y márcala como enviada.'
                  : 'No pudimos abrir el navegador. Inténtalo de nuevo.',
            ),
          ));
      },
    );
  }
}

/// US-14 · «Marcar como enviado» with confirmation: the request was presented by other
/// means (portal, shared PDF). The report becomes «Enviado (manual)».
class MarkAsSentButton extends ConsumerStatefulWidget {
  const MarkAsSentButton({super.key, required this.reportId});

  final String reportId;

  @override
  ConsumerState<MarkAsSentButton> createState() => _MarkAsSentButtonState();
}

class _MarkAsSentButtonState extends ConsumerState<MarkAsSentButton> {
  bool _busy = false;

  Future<void> _mark() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Marcar como enviado'),
        content: const Text(
          '¿Ya presentaste esta solicitud por tu cuenta, por ejemplo en el portal oficial o '
          'compartiendo el PDF? El reporte quedará como «Enviado (manual)».',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Marcar como enviado'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(reportsRepositoryProvider).markAsSent(widget.reportId);
      messenger.showSnackBar(const SnackBar(content: Text('Reporte marcado como enviado.')));
    } on ApiException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      // Refresh every screen that shows the status (also after a 409).
      ref.invalidate(reportDetailProvider(widget.reportId));
      ref.invalidate(pqrsdPreviewProvider(widget.reportId));
      ref.invalidate(reportsListProvider);
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: _busy
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.task_alt),
      label: const Text('Marcar como enviado'),
      onPressed: _busy ? null : _mark,
    );
  }
}
