import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';

/// «Paso X de N» with a progress bar, for the new-report steps.
class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.step, this.total = 4});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Paso $step de $total', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.xs),
          child: LinearProgressIndicator(
            value: step / total,
            minHeight: 6,
            backgroundColor: AppColors.primaryContainer,
          ),
        ),
      ],
    );
  }
}
