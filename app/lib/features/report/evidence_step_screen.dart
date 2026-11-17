import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/router.dart';
import '../../core/theme.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/step_progress.dart';
import 'evidence_picker.dart';
import 'report_draft.dart';

/// Screen 05 · Nuevo reporte, paso 1 de 4: Evidencia (US-05, RF-02).
class EvidenceStepScreen extends ConsumerStatefulWidget {
  const EvidenceStepScreen({super.key});

  @override
  ConsumerState<EvidenceStepScreen> createState() => _EvidenceStepScreenState();
}

class _EvidenceStepScreenState extends ConsumerState<EvidenceStepScreen> {
  bool _busy = false;

  ReportDraftController get _draft => ref.read(reportDraftProvider.notifier);

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Adds the picked files that pass the phone-side checks; explains the rest.
  void _addPicked(List<PickedMedia> picked) {
    final problems = <String>{};
    for (final media in picked) {
      if (!_draft.canAddEvidence) {
        problems.add('Puedes adjuntar máximo ${EvidenceLimits.maxFiles} archivos.');
        break;
      }
      if (media.isUnsupportedFormat) {
        problems.add('Formato de foto no compatible (HEIC). Usa JPG o PNG.');
        continue;
      }
      if (media.isVideo && media.sizeBytes > EvidenceLimits.maxVideoBytes) {
        problems.add('El video supera ${EvidenceLimits.maxVideoBytes ~/ (1024 * 1024)} MB. '
            'Graba uno más corto.');
        continue;
      }
      if (!media.isVideo && media.sizeBytes > EvidenceLimits.maxPhotoBytes) {
        problems.add('La foto supera ${EvidenceLimits.maxPhotoBytes ~/ (1024 * 1024)} MB.');
        continue;
      }
      _draft.addEvidence(EvidenceFile(
        path: media.path,
        kind: media.isVideo ? EvidenceKind.video : EvidenceKind.photo,
        sizeBytes: media.sizeBytes,
      ));
    }
    if (problems.isNotEmpty) _showMessage(problems.join('\n'));
  }

  Future<void> _pick(Future<List<PickedMedia>> Function(EvidencePicker picker) action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final picked = await action(ref.read(evidencePickerProvider));
      if (mounted) _addPicked(picked);
    } catch (_) {
      if (mounted) _showMessage('No pudimos abrir la cámara o la galería. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<List<PickedMedia>> _single(Future<PickedMedia?> future) async {
    final media = await future;
    return media == null ? const [] : [media];
  }

  /// Leaving step 1 discards the report (there are no drafts), so ask first.
  Future<void> _confirmExit() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Descartar el reporte?'),
        content: const Text('Se perderá la evidencia y los datos que ingresaste.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Seguir editando'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      _draft.reset();
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(reportDraftProvider);
    final canAdd = draft.evidence.length < EvidenceLimits.maxFiles && !_busy;

    return PopScope(
      canPop: draft.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Nuevo reporte')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const StepProgress(step: 1),
              const SizedBox(height: AppSpacing.lg),
              Text('Captura la evidencia', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              const Text('Procura que se vea la placa y el humo.'),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: canAdd ? () => _pick((p) => _single(p.takePhoto())) : null,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Tomar foto'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: canAdd ? () => _pick((p) => _single(p.recordVideo())) : null,
                icon: const Icon(Icons.videocam_outlined),
                label: const Text('Grabar video (máx. 15 s)'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: canAdd
                    ? () => _pick((p) => p.pickFromGallery(limit: _draft.remainingEvidence))
                    : null,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Elegir de la galería'),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '${draft.evidence.length} de ${EvidenceLimits.maxFiles} archivos',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (draft.evidence.isNotEmpty)
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final file in draft.evidence)
                      EvidenceThumbnail(
                        file: file,
                        onRemove: () => _draft.removeEvidence(file),
                      ),
                  ],
                ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Siguiente',
                onPressed: draft.evidence.isEmpty || _busy
                    ? null
                    : () => context.push(Routes.reportVehicle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Size in MB with a decimal comma, e.g. «3,2 MB».
String formatMegabytes(int bytes) {
  final mb = bytes / (1024 * 1024);
  return '${mb.toStringAsFixed(1).replaceAll('.', ',')} MB';
}

/// Square thumbnail: the photo itself, or a «Video» card with icon and size.
class EvidenceThumbnail extends StatelessWidget {
  const EvidenceThumbnail({super.key, required this.file, this.onRemove});

  static const double size = 104;

  final EvidenceFile file;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final content = file.isVideo
        ? Container(
            color: AppColors.primaryContainer,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.videocam, size: 36, color: AppColors.primary),
                const Text('Video'),
                Text(formatMegabytes(file.sizeBytes), style: const TextStyle(fontSize: 12)),
              ],
            ),
          )
        : Image.file(
            File(file.path),
            fit: BoxFit.cover,
            cacheWidth: 300,
            errorBuilder: (context, error, stack) => const ColoredBox(
              color: AppColors.primaryContainer,
              child: Center(child: Icon(Icons.image_outlined, color: AppColors.primary)),
            ),
          );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(AppSpacing.radius), child: content),
          if (onRemove != null)
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                tooltip: 'Quitar',
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                color: Colors.white,
                icon: const Icon(Icons.close),
                onPressed: onRemove,
              ),
            ),
        ],
      ),
    );
  }
}
