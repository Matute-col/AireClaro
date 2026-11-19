import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';

/// Report status «Generado» / «Enviado por correo» / «Enviado (manual)» (docs/06).
/// Icon + text, not only color (accessibility).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.sentVia});

  final String status;

  /// `email` or `manual` (only when sent).
  final String? sentVia;

  String get _label {
    if (status != 'enviado') return 'Generado';
    return switch (sentVia) {
      'email' => 'Enviado por correo',
      'manual' => 'Enviado (manual)',
      _ => 'Enviado',
    };
  }

  @override
  Widget build(BuildContext context) {
    final sent = status == 'enviado';
    const color = AppColors.onChip;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        border: Border.all(color: AppColors.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(sent ? Icons.check_circle : Icons.description_outlined, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            _label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
