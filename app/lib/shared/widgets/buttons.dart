import 'package:material_ui/material_ui.dart';

/// Filled main action. Shows a spinner and ignores taps while [loading].
/// Pass `onPressed: null` to disable it.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
          )
        : Text(label);

    if (icon != null && !loading) {
      return FilledButton.icon(onPressed: onPressed, icon: Icon(icon), label: child);
    }
    return FilledButton(onPressed: loading ? null : onPressed, child: child);
  }
}

/// Outlined secondary action.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(onPressed: onPressed, child: Text(label));
  }
}
