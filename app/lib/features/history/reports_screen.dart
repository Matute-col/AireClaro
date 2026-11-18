import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/router.dart';
import '../../core/theme.dart';
import '../../shared/widgets/auth_image.dart';
import '../../shared/widgets/states.dart';
import '../../shared/widgets/status_chip.dart';
import '../report/report_draft.dart';
import 'report_summary.dart';
import 'reports_list_controller.dart';

/// «16 nov 2026, 9:30 a. m.»
String formatShortDate(DateTime date) => DateFormat("d MMM y, h:mm a", 'es_CO').format(date);

/// Screen 12 · Mis reportes (US-10, RF-09).
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  void _newReport(BuildContext context, WidgetRef ref) {
    ref.read(reportDraftProvider.notifier).reset();
    context.push(Routes.reportEvidence);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportsListProvider);
    final controller = ref.read(reportsListProvider.notifier);

    Widget body;
    if (state.loading && state.items.isEmpty) {
      body = const LoadingState(message: 'Cargando tus reportes…');
    } else if (state.error != null) {
      body = ErrorState(message: state.error!, onRetry: controller.refresh);
    } else if (state.isEmpty) {
      body = EmptyState(
        icon: Icons.list_alt,
        title: 'Aún no tienes reportes',
        message: 'Cuando crees uno, aparecerá aquí con su estado.',
        actionLabel: 'Nuevo reporte',
        onAction: () => _newReport(context, ref),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: controller.refresh,
        child: NotificationListener<ScrollNotification>(
          // Load the next page when the user gets near the end of the list.
          onNotification: (notification) {
            if (notification.metrics.extentAfter < 300) controller.loadMore();
            return false;
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: state.items.length + 1,
            itemBuilder: (context, index) {
              if (index < state.items.length) {
                final report = state.items[index];
                return ReportCard(
                  report: report,
                  onTap: () => context.push(Routes.reportDetail(report.id)),
                );
              }
              return _ListFooter(state: state, onRetry: controller.loadMore);
            },
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mis reportes')),
      body: body,
    );
  }
}

class _ListFooter extends StatelessWidget {
  const _ListFooter({required this.state, required this.onRetry});

  final ReportsListState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.loadMoreError != null) {
      return MessageBanner(message: state.loadMoreError!, actionLabel: 'Reintentar', onAction: onRetry);
    }
    if (!state.hasMore && state.total > 0) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          state.total == 1 ? '1 reporte' : '${state.total} reportes',
          textAlign: TextAlign.center,
        ),
      );
    }
    return const SizedBox(height: AppSpacing.xl);
  }
}

/// Thumbnail, plate, vehicle type, date and status (docs/06 · ReportCard).
class ReportCard extends StatelessWidget {
  const ReportCard({super.key, required this.report, this.onTap});

  final ReportSummary report;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final thumbnailId = report.thumbnailMediaId;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radius),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: thumbnailId != null
                      ? AuthNetworkImage(url: mediaUrl(report.id, thumbnailId), cacheWidth: 200)
                      : const ColoredBox(
                          color: AppColors.primaryContainer,
                          child: Icon(Icons.videocam, color: AppColors.primary),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report.plate, style: textTheme.titleMedium),
                    Text(vehicleTypeLabels[report.vehicleType] ?? report.vehicleType),
                    Text(formatShortDate(report.occurredAt), style: textTheme.bodySmall),
                    const SizedBox(height: AppSpacing.xs),
                    StatusChip(status: report.status, sentVia: report.sentVia),
                  ],
                ),
              ),
              if (onTap != null) const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
