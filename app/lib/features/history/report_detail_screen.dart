import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/api_error.dart';
import '../../core/theme.dart';
import '../../core/router.dart';
import '../../shared/services/file_actions.dart';
import '../../shared/widgets/auth_image.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/report_mini_map.dart';
import '../../shared/widgets/states.dart';
import '../../shared/widgets/status_chip.dart';
import '../report/evidence_step_screen.dart';
import '../report/location_step_screen.dart';
import '../report/report_draft.dart';
import '../report/reports_repository.dart';
import '../pqrsd/delivery_actions.dart';
import '../pqrsd/pdf_actions.dart';
import '../map/map_reports.dart';
import 'report_detail.dart';
import 'reports_list_controller.dart';

/// Detail of one of the user's reports.
final reportDetailProvider = FutureProvider.family<ReportDetail, String>(
  (ref, id) => ref.watch(reportsRepositoryProvider).getById(id),
);

/// Screen 13 · Detalle del reporte (US-11, RF-15). The download, send and portal
/// buttons arrive in Sprint 3 (US-12…US-14, US-21, US-22).
class ReportDetailScreen extends ConsumerWidget {
  const ReportDetailScreen({super.key, required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(reportDetailProvider(reportId));
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del reporte')),
      body: detail.when(
        loading: () => const LoadingState(message: 'Cargando el reporte…'),
        error: (error, _) {
          final apiError = toApiException(error);
          if (apiError.statusCode == 404) {
            return const EmptyState(
              icon: Icons.search_off,
              title: 'No encontramos este reporte',
              message: 'Puede que ya no exista o que no sea tuyo.',
            );
          }
          return ErrorState(
            message: apiError.message,
            onRetry: () => ref.invalidate(reportDetailProvider(reportId)),
          );
        },
        data: (report) => _DetailBody(report: report),
      ),
    );
  }
}

/// US-18 · «Eliminar reporte» with confirmation (RF-16). Removes the report, its evidence
/// and its frames; then goes back and refreshes the list, the count and the map.
class _DeleteButton extends ConsumerStatefulWidget {
  const _DeleteButton({required this.report});

  final ReportDetail report;

  @override
  ConsumerState<_DeleteButton> createState() => _DeleteButtonState();
}

class _DeleteButtonState extends ConsumerState<_DeleteButton> {
  bool _busy = false;

  Future<void> _delete() async {
    final sent = widget.report.status == 'enviado';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar este reporte?'),
        content: Text(
          'Se borrarán la evidencia, los fotogramas y la solicitud de AireClaro. No se puede deshacer.'
          '${sent ? '\n\nLa solicitud que ya se presentó a la autoridad no se retira.' : ''}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(reportsRepositoryProvider).deleteReport(widget.report.id);
      ref.invalidate(reportsListProvider);
      ref.invalidate(reportsCountProvider);
      ref.invalidate(mapReportsProvider);
      messenger.showSnackBar(const SnackBar(content: Text('Reporte eliminado.')));
      router.canPop() ? router.pop() : router.go(Routes.reports);
    } on ApiException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(foregroundColor: AppColors.danger),
      onPressed: _busy ? null : _delete,
      icon: _busy
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.delete_outline),
      label: const Text('Eliminar reporte'),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.report});

  final ReportDetail report;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _EvidenceCarousel(reportId: report.id, media: report.media),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: Text(report.plate, style: textTheme.headlineSmall)),
            StatusChip(status: report.status, sentVia: report.sentVia),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // US-21: sending happens in the preview, where the full text is visible.
        if (report.authority.canEmail && report.status == 'generado') ...[
          PrimaryButton(
            label: 'Enviar a la autoridad',
            icon: Icons.send_outlined,
            onPressed: () => context.push(Routes.reportPreview(report.id)),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        // US-13: the request of this report.
        SecondaryButton(
          label: 'Ver solicitud',
          onPressed: () => context.push(Routes.reportPreview(report.id)),
        ),
        const SizedBox(height: AppSpacing.sm),
        PdfActions(reportId: report.id, plate: report.plate),
        // US-22 / US-14: official portal and «Marcar como enviado» (docs/06, screen 13).
        if (report.authority.portalUrl != null) ...[
          const SizedBox(height: AppSpacing.sm),
          PortalButton(portalUrl: report.authority.portalUrl!),
        ],
        if (report.status == 'generado') ...[
          const SizedBox(height: AppSpacing.sm),
          MarkAsSentButton(reportId: report.id),
        ],
        const SizedBox(height: AppSpacing.md),
        _Card(title: 'Vehículo', lines: [
          ('Tipo', vehicleTypeLabels[report.vehicleType] ?? report.vehicleType),
          ('Color del humo', smokeColorLabels[report.smokeColor] ?? report.smokeColor),
          if (report.description != null) ('Descripción', report.description!),
        ]),
        _Card(
          title: 'Ubicación y hora',
          lines: [
            ('Dirección', report.address ?? 'Sin dirección aproximada'),
            ('Fecha y hora', formatReportDate(report.occurredAt)),
          ],
          top: ReportMiniMap(point: LatLng(report.lat, report.lng)),
        ),
        _Card(title: 'Autoridad destinataria', lines: [
          ('Entidad', report.authority.name),
          ('Estado', report.status == 'enviado' ? 'Solicitud enviada' : 'Solicitud generada, aún sin enviar'),
          if (report.sentAt != null) ('Enviada el', formatReportDate(report.sentAt!)),
        ]),
        _Card(title: 'Peticionario', lines: [
          ('Nombre', report.requesterName),
          ('Documento', '${report.requesterDocType} ${report.requesterDocNumber}'),
          ('Correo', report.requesterEmail),
          if (report.requesterPhone != null) ('Teléfono', report.requesterPhone!),
        ]),
        const Text(
          'AireClaro no mide emisiones ni impone sanciones. Genera una solicitud con la '
          'evidencia que tú aportas.',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: AppSpacing.lg),
        _DeleteButton(report: report),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

/// Swipeable evidence: photos loaded with the token; videos as a «Video» card.
class _EvidenceCarousel extends StatefulWidget {
  const _EvidenceCarousel({required this.reportId, required this.media});

  final String reportId;
  final List<ReportMedia> media;

  @override
  State<_EvidenceCarousel> createState() => _EvidenceCarouselState();
}

class _EvidenceCarouselState extends State<_EvidenceCarousel> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.media.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 260,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            child: PageView.builder(
              itemCount: widget.media.length,
              onPageChanged: (page) => setState(() => _page = page),
              itemBuilder: (context, index) {
                final item = widget.media[index];
                if (item.isVideo) return _VideoCard(reportId: widget.reportId, media: item);
                return ColoredBox(
                  color: Colors.black,
                  child: AuthNetworkImage(
                    url: mediaUrl(widget.reportId, item.id),
                    fit: BoxFit.contain,
                    cacheWidth: 1200,
                  ),
                );
              },
            ),
          ),
        ),
        if (widget.media.length > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          Text('${_page + 1} de ${widget.media.length} · desliza para ver más'),
        ],
        // US-23: the frames of the video shown above.
        if (widget.media[_page].isVideo && widget.media[_page].frames.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _FramesRow(reportId: widget.reportId, frames: widget.media[_page].frames),
        ],
      ],
    );
  }
}

/// Video evidence: there is no player in the app, so it is downloaded with the
/// session and opened with the phone's video app (CP-07).
class _VideoCard extends ConsumerStatefulWidget {
  const _VideoCard({required this.reportId, required this.media});

  final String reportId;
  final ReportMedia media;

  @override
  ConsumerState<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends ConsumerState<_VideoCard> {
  bool _opening = false;

  Future<void> _open() async {
    setState(() => _opening = true);
    String? problem;
    try {
      final path = await ref
          .read(reportsRepositoryProvider)
          .downloadMedia(widget.reportId, widget.media.id, widget.media.extension);
      problem = await ref.read(fileActionsProvider).open(path);
    } on ApiException catch (error) {
      problem = error.message;
    } finally {
      if (mounted) setState(() => _opening = false);
    }
    if (problem != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(problem)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.primaryContainer,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam, size: 56, color: AppColors.primary),
          const SizedBox(height: AppSpacing.sm),
          Text('Video · ${formatMegabytes(widget.media.sizeBytes)}'),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            onPressed: _opening ? null : _open,
            icon: _opening
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimaryButton),
                  )
                : const Icon(Icons.play_arrow),
            label: const Text('Abrir video'),
          ),
        ],
      ),
    );
  }
}

/// US-23 · Frames of a video in a row, with the note that they were extracted from it.
class _FramesRow extends StatelessWidget {
  const _FramesRow({required this.reportId, required this.frames});

  final String reportId;
  final List<ReportFrame> frames;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fotogramas del video (${frames.length}) · extraídos al 10 %, 35 %, 65 % y 90 % de su duración',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            for (final (i, frame) in frames.indexed) ...[
              if (i > 0) const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.xs),
                    child: AuthNetworkImage(
                      key: ValueKey(frame.id),
                      url: mediaUrl(reportId, frame.id),
                      cacheWidth: 300,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.lines, this.top});

  final String title;
  final List<(String, String)> lines;
  final Widget? top;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            if (top != null) ...[top!, const SizedBox(height: AppSpacing.sm)],
            for (final (label, value) in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(text: value),
                ])),
              ),
          ],
        ),
      ),
    );
  }
}
