import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';

/// Short data-processing policy (Ley 1581 de 2012). Used in registration and profile.
Future<void> showPrivacyPolicyDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Tratamiento de datos personales'),
      content: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _PolicySection(
              title: 'Qué datos recogemos',
              body: 'Tus datos de contacto (nombre, tipo y número de documento, correo y '
                  'teléfono) y, en cada reporte, la ubicación, las fotos o videos y la '
                  'placa del vehículo.',
            ),
            _PolicySection(
              title: 'Para qué',
              body: 'Para generar tu solicitud (PQRSD) ante la autoridad competente y '
                  'mostrarte tu historial de reportes. Cuando tú decides enviar una '
                  'solicitud, tus datos de peticionario y la evidencia se comparten con '
                  'esa autoridad. El mapa de reportes no muestra placas ni fotos.',
            ),
            _PolicySection(
              title: 'Tus derechos',
              body: 'De acuerdo con la Ley 1581 de 2012 puedes conocer, actualizar y '
                  'rectificar tus datos. Puedes editarlos en tu perfil.',
            ),
            Text(
              'AireClaro es un prototipo académico (UNAD). No mide emisiones ni impone '
              'sanciones.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(body),
        ],
      ),
    );
  }
}
