import 'package:material_ui/material_ui.dart';

import 'states.dart';

/// Placeholder for a main tab whose story belongs to a later sprint
/// (Mapa: US-15, Mis reportes: US-10, Info: US-16).
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: EmptyState(
        icon: icon,
        title: 'Muy pronto',
        message: 'Esta sección estará disponible en una próxima versión de AireClaro.',
      ),
    );
  }
}
