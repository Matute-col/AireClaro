import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Tiles are turned off in widget tests (no network there).
final mapTilesEnabledProvider = Provider<bool>((ref) => true);

/// OpenStreetMap public tiles (light use, prototype). The User-Agent carries the
/// app id, as the OSM tile policy asks.
class OsmTileLayer extends ConsumerWidget {
  const OsmTileLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(mapTilesEnabledProvider)) return const SizedBox.shrink();
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.aireclaro.app',
      maxNativeZoom: 19,
    );
  }
}

/// «© OpenStreetMap contributors», always visible on every map (CLAUDE.md, RNF-09).
class OsmAttribution extends StatelessWidget {
  const OsmAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        color: Colors.white.withValues(alpha: 0.85),
        child: const Text(
          '© OpenStreetMap contributors',
          style: TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ),
    );
  }
}
