import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';

/// Report status «Generado» / «Enviado». Icon + text, not only color (accessibility).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final sent = status == 'enviado';
    final color = sent ? AppColors.success : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(sent ? Icons.check_circle : Icons.description_outlined, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            sent ? 'Enviado' : 'Generado',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
