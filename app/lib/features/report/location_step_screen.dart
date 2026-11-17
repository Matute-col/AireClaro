import 'dart:async';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/api_error.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/osm_map.dart';
import '../../shared/widgets/states.dart';
import '../../shared/widgets/step_progress.dart';
import 'geo_repository.dart';
import 'location_service.dart';
import 'report_draft.dart';

/// Default map center when there is no GPS: Soacha–Bogotá corridor (docs/06).
const corridorCenter = LatLng(4.595, -74.15);

/// «domingo 16 de noviembre de 2026, 3:45 p. m.»
String formatReportDate(DateTime date) =>
    DateFormat("EEEE d 'de' MMMM 'de' y, h:mm a", 'es_CO').format(date);

/// Screen 07 · Paso 3 de 4: Ubicación y hora (US-07, RF-03).
class LocationStepScreen extends ConsumerStatefulWidget {
  const LocationStepScreen({super.key});

  @override
  ConsumerState<LocationStepScreen> createState() => _LocationStepScreenState();
}

class _LocationStepScreenState extends ConsumerState<LocationStepScreen> {
  final _map = MapController();
  bool _mapReady = false;
  bool _locating = false;
  LocationIssue? _issue;
  bool _geoLoading = false;
  String? _geoError;
  Timer? _debounce;

  /// Increases on every new pin, so a slow old answer cannot overwrite a newer one.
  int _lookupId = 0;

  ReportDraftController get _draft => ref.read(reportDraftProvider.notifier);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _draft.startLocationStep(DateTime.now());
      final draft = ref.read(reportDraftProvider);
      if (draft.hasLocation) {
        if (draft.address == null) _lookupAddress(draft.lat!, draft.lng!);
      } else {
        _useCurrentLocation();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _map.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _locating = true;
      _issue = null;
    });
    final result = await ref.read(locationServiceProvider).current();
    if (!mounted) return;
    setState(() {
      _locating = false;
      _issue = result.issue;
    });
    if (result.isOk) _setPoint(LatLng(result.lat!, result.lng!), moveMap: true);
  }

  void _setPoint(LatLng point, {bool moveMap = false}) {
    _draft.setPoint(point.latitude, point.longitude);
    if (moveMap && _mapReady) _map.move(point, 17);
    setState(() {
      _geoError = null;
      _geoLoading = true;
    });
    // Wait until the user stops moving the pin: fewer requests to the geocoder.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      _lookupAddress(point.latitude, point.longitude);
    });
  }

  Future<void> _lookupAddress(double lat, double lng) async {
    final id = ++_lookupId;
    setState(() {
      _geoLoading = true;
      _geoError = null;
    });
    try {
      final result = await ref.read(geoRepositoryProvider).reverse(lat, lng);
      if (!mounted || id != _lookupId) return;
      _draft.setGeo(
        address: result.address,
        municipality: result.municipality,
        suggestedAuthorityId: result.suggestedAuthorityId,
      );
      setState(() => _geoLoading = false);
    } on ApiException catch (error) {
      if (!mounted || id != _lookupId) return;
      setState(() {
        _geoLoading = false;
        _geoError = error.isNetworkError ? error.message : 'No pudimos obtener la dirección. Puedes continuar; la autoridad se elige en la revisión.';
      });
    }
  }

  Future<void> _activateLocation() async {
    final issue = _issue;
    if (issue == LocationIssue.serviceDisabled ||
        issue == LocationIssue.deniedForever) {
      await ref.read(locationServiceProvider).openSettings(issue!);
    } else {
      await _useCurrentLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(reportDraftProvider);
    final textTheme = Theme.of(context).textTheme;
    final point = draft.hasLocation ? LatLng(draft.lat!, draft.lng!) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo reporte')),
      body: SafeArea(
        // Column (not ListView) so the map keeps its state when the notice above
        // appears or disappears: a ListView would rebuild it with a stale controller.
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const StepProgress(step: 3),
              const SizedBox(height: AppSpacing.lg),
              Text('Ubicación y hora', style: textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              if (_issue != null) ...[
                _LocationIssueBanner(
                  issue: _issue!,
                  onActivate: _activateLocation,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              SizedBox(
                key: const ValueKey('location-map'),
                height: 300,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _map,
                        options: MapOptions(
                          initialCenter: point ?? corridorCenter,
                          initialZoom: point != null ? 17 : 12,
                          onMapReady: () => _mapReady = true,
                          onTap: (_, tapped) => _setPoint(tapped),
                        ),
                        children: [
                          const OsmTileLayer(),
                          if (point != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: point,
                                  width: 48,
                                  height: 48,
                                  alignment: Alignment.topCenter,
                                  child: const Icon(
                                    Icons.location_on,
                                    size: 48,
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const OsmAttribution(),
                      if (_locating)
                        const Center(child: CircularProgressIndicator()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text('Toca el mapa para mover el pin al lugar exacto.'),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: _locating ? null : _useCurrentLocation,
                icon: const Icon(Icons.my_location),
                label: const Text('Usar mi ubicación actual'),
              ),
              const SizedBox(height: AppSpacing.md),
              _InfoRow(
                icon: Icons.place_outlined,
                label: 'Dirección aproximada',
                child: _addressText(draft),
              ),
              _InfoRow(
                icon: Icons.schedule,
                label: 'Fecha y hora',
                child: Text(
                  draft.occurredAt == null
                      ? '—'
                      : formatReportDate(draft.occurredAt!),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Atrás',
                      onPressed: () => context.pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Siguiente',
                      onPressed: point == null
                          ? null
                          : () => context.push(Routes.reportRequester),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addressText(ReportDraft draft) {
    if (!draft.hasLocation) {
      return const Text('Marca en el mapa dónde ocurrió.');
    }
    if (_geoLoading) return const Text('Buscando dirección…');
    if (_geoError != null) {
      return Text(_geoError!, style: const TextStyle(color: AppColors.warning));
    }
    return Text(
      draft.address ?? 'Sin dirección para este punto. Puedes continuar.',
    );
  }
}

class _LocationIssueBanner extends StatelessWidget {
  const _LocationIssueBanner({required this.issue, required this.onActivate});

  final LocationIssue issue;
  final VoidCallback onActivate;

  String get _message => switch (issue) {
    LocationIssue.serviceDisabled => 'La ubicación del teléfono está apagada. Actívala para registrar dónde ocurrió.',
    LocationIssue.unavailable => 'No pudimos obtener tu ubicación. Inténtalo al aire libre o toca el mapa.',
    _ => 'Necesitamos tu ubicación para registrar dónde ocurrió.',
  };

  @override
  Widget build(BuildContext context) {
    return MessageBanner(
      message: _message,
      isError: false,
      actionLabel: issue == LocationIssue.unavailable
          ? 'Reintentar'
          : 'Activar ubicación',
      onAction: onActivate,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: AppSpacing.xs),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
