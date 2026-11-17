import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/api_error.dart';
import '../../core/theme.dart';
import '../../shared/widgets/auth_image.dart';
import '../../shared/widgets/report_mini_map.dart';
import '../../shared/widgets/states.dart';
import '../../shared/widgets/status_chip.dart';
import '../report/evidence_step_screen.dart';
import '../report/location_step_screen.dart';
import '../report/report_draft.dart';
import '../report/reports_repository.dart';
import 'report_detail.dart';

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
            StatusChip(status: report.status),
          ],
        ),
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
                if (item.isVideo) {
                  return ColoredBox(
                    color: AppColors.primaryContainer,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.videocam, size: 56, color: AppColors.primary),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Video · ${formatMegabytes(item.sizeBytes)}'),
                      ],
                    ),
                  );
                }
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
