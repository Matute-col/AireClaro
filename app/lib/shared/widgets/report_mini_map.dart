import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import 'osm_map.dart';

/// Small non-interactive map with the report pin (review and detail screens).
class ReportMiniMap extends StatelessWidget {
  const ReportMiniMap({super.key, required this.point, this.height = 160});

  final LatLng point;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: 16,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
              ),
              children: [
                const OsmTileLayer(),
                MarkerLayer(markers: [
                  Marker(
                    point: point,
                    width: 40,
                    height: 40,
                    alignment: Alignment.topCenter,
                    child: const Icon(Icons.location_on, size: 40, color: AppColors.mapPinSelected),
                  ),
                ]),
              ],
            ),
            const OsmAttribution(),
          ],
        ),
      ),
    );
  }
}
