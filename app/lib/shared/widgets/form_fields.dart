import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Text field with a visible label. Set [obscure] for passwords: it adds a
/// show/hide button.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.validator,
    this.errorText,
    this.hintText,
    this.helperText,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.autofillHints,
    this.obscure = false,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;

  /// Error that comes from the API (e.g. email already registered).
  final String? errorText;
  final String? hintText;
  final String? helperText;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final bool obscure;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      inputFormatters: widget.inputFormatters,
      autofillHints: widget.autofillHints,
      obscureText: _hidden,
      enableSuggestions: !widget.obscure,
      autocorrect: !widget.obscure,
      enabled: widget.enabled,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText,
        helperText: widget.helperText,
        errorText: widget.errorText,
        errorMaxLines: 3,
        suffixIcon: widget.obscure
            ? IconButton(
                tooltip: _hidden ? 'Mostrar contraseña' : 'Ocultar contraseña',
                icon: Icon(_hidden ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _hidden = !_hidden),
              )
            : null,
      ),
    );
  }
}

/// Dropdown with a visible label. [options] maps the value sent to the API to
/// the text shown to the user.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.validator,
  });

  final String label;
  final Map<T, String> options;
  final T? value;
  final ValueChanged<T?> onChanged;
  final FormFieldValidator<T>? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final entry in options.entries)
          DropdownMenuItem<T>(value: entry.key, child: Text(entry.value)),
      ],
      onChanged: onChanged,
    );
  }
}
