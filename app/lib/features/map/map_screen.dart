import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/api_error.dart';
import '../../core/theme.dart';
import '../../shared/widgets/osm_map.dart';
import '../../shared/widgets/states.dart';
import '../report/location_step_screen.dart';
import '../report/report_draft.dart';
import 'map_reports.dart';

/// Screen 14 · Mapa de reportes (US-15, RF-10). Pins of every user's reports with
/// filters by vehicle type and date. Tapping a pin shows only type and date (RB-07).
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapReport? _selected;

  @override
  Widget build(BuildContext context) {
    final reports = ref.watch(mapReportsProvider);
    final pins = reports.value ?? const <MapReport>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de reportes'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(mapReportsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          const _FiltersBar(),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: corridorCenter,
                    initialZoom: 11,
                    onTap: (_, _) => setState(() => _selected = null),
                  ),
                  children: [
                    const OsmTileLayer(),
                    MarkerLayer(markers: [
                      for (final pin in pins)
                        Marker(
                          point: LatLng(pin.lat, pin.lng),
                          width: 44,
                          height: 44,
                          alignment: Alignment.topCenter,
                          child: GestureDetector(
                            key: ValueKey('pin-${pin.id}'),
                            onTap: () => setState(() => _selected = pin),
                            child: Icon(
                              Icons.location_on,
                              size: 44,
                              color: pin.id == _selected?.id ? AppColors.mapPinSelected : AppColors.mapPin,
                            ),
                          ),
                        ),
                    ]),
                  ],
                ),
                const OsmAttribution(),
                Positioned(
                  top: AppSpacing.sm,
                  left: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: _StatusBanner(reports: reports),
                ),
                if (_selected != null)
                  Positioned(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    bottom: AppSpacing.xl,
                    child: _PinCard(
                      report: _selected!,
                      onClose: () => setState(() => _selected = null),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading, error with «Reintentar», empty, or how many reports are shown.
class _StatusBanner extends ConsumerWidget {
  const _StatusBanner({required this.reports});

  final AsyncValue<List<MapReport>> reports;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (reports.isLoading) {
      return const Align(
        alignment: Alignment.topLeft,
        child: Chip(
          avatar: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          label: Text('Cargando reportes…'),
        ),
      );
    }
    if (reports.hasError) {
      return MessageBanner(
        message: toApiException(reports.error!).message,
        actionLabel: 'Reintentar',
        onAction: () => ref.invalidate(mapReportsProvider),
      );
    }
    final count = reports.value!.length;
    if (count == 0) {
      return const MessageBanner(message: 'No hay reportes con estos filtros.', isError: false);
    }
    return Align(
      alignment: Alignment.topLeft,
      child: Chip(label: Text(count == 1 ? '1 reporte' : '$count reportes')),
    );
  }
}

/// Vehicle type chips and date period chips.
class _FiltersBar extends ConsumerWidget {
  const _FiltersBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(mapFiltersProvider);
    final controller = ref.read(mapFiltersProvider.notifier);
    return Material(
      color: AppColors.surface,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                children: [
                  for (final entry in vehicleTypeLabels.entries) ...[
                    FilterChip(
                      label: Text(entry.value),
                      selected: filters.vehicleTypes.contains(entry.key),
                      onSelected: (_) => controller.toggleType(entry.key),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                children: [
                  for (final period in MapPeriod.values) ...[
                    ChoiceChip(
                      label: Text(period.label),
                      selected: filters.period == period,
                      onSelected: (_) => controller.setPeriod(period),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  if (!filters.isDefault)
                    TextButton(onPressed: controller.clear, child: const Text('Limpiar filtros')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card of a tapped pin: ONLY vehicle type and date (RB-07, CP-18).
class _PinCard extends StatelessWidget {
  const _PinCard({required this.report, required this.onClose});

  final MapReport report;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: ListTile(
        leading: const Icon(Icons.local_shipping_outlined, color: AppColors.primary),
        title: Text(vehicleTypeLabels[report.vehicleType] ?? report.vehicleType),
        subtitle: Text(formatReportDate(report.occurredAt)),
        trailing: IconButton(tooltip: 'Cerrar', icon: const Icon(Icons.close), onPressed: onClose),
      ),
    );
  }
}
