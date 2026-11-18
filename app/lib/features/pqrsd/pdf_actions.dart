import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/api_error.dart';
import '../../core/theme.dart';
import '../../shared/services/file_actions.dart';
import '../report/reports_repository.dart';

/// «Descargar PDF» (downloads and opens it) and «Compartir» (phone share menu).
/// Used by the preview (screen 10) and the report detail (screen 13).
class PdfActions extends ConsumerStatefulWidget {
  const PdfActions({super.key, required this.reportId, required this.plate});

  final String reportId;
  final String plate;

  @override
  ConsumerState<PdfActions> createState() => _PdfActionsState();
}

class _PdfActionsState extends ConsumerState<PdfActions> {
  /// Which action is running: 'open', 'share' or null.
  String? _busy;

  /// The PDF is downloaded once per screen and reused for both buttons.
  String? _localPath;

  Future<String> _pdfPath() async {
    return _localPath ??= await ref.read(reportsRepositoryProvider).downloadPdf(widget.reportId);
  }

  void _message(String text, {VoidCallback? retry}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text),
        action: retry == null ? null : SnackBarAction(label: 'Reintentar', onPressed: retry),
      ));
  }

  Future<void> _run(String action, Future<void> Function(String path) body) async {
    if (_busy != null) return;
    setState(() => _busy = action);
    try {
      await body(await _pdfPath());
    } on ApiException catch (error) {
      _localPath = null;
      if (mounted) _message(error.message, retry: () => _run(action, body));
    } catch (_) {
      if (mounted) _message('No pudimos completar la acción. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _open() => _run('open', (path) async {
        final problem = await ref.read(fileActionsProvider).open(path);
        if (problem != null && mounted) _message(problem);
      });

  Future<void> _share() => _run('share', (path) {
        return ref.read(fileActionsProvider).share(
              path,
              mimeType: 'application/pdf',
              subject: 'Solicitud ciudadana – vehículo de placa ${widget.plate}',
            );
      });

  Widget _icon(String action, IconData icon) => _busy == action
      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
      : Icon(icon);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _busy == null ? _open : null,
            icon: _icon('open', Icons.picture_as_pdf_outlined),
            label: const Text('Descargar PDF'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _busy == null ? _share : null,
            icon: _icon('share', Icons.share_outlined),
            label: const Text('Compartir'),
          ),
        ),
      ],
    );
  }
}
