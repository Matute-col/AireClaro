import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/api_error.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/form_fields.dart';
import '../../shared/widgets/privacy_policy_dialog.dart';
import '../../shared/widgets/states.dart';
import 'auth_controller.dart';
import 'auth_repository.dart';
import 'user.dart';

/// Screen 03 · Registro (UC-01, RF-01, RF-11).
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _docNumber = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _docType;
  bool _acceptTerms = false;
  bool _loading = false;

  /// Errors returned by the API, per field (e.g. email already registered).
  Map<String, String> _serverErrors = {};

  /// General error (no connection, server error).
  String? _generalError;

  @override
  void initState() {
    super.initState();
    // Re-check the button state on every change.
    for (final controller in [_fullName, _docNumber, _email, _phone, _password, _confirm]) {
      controller.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    for (final controller in [_fullName, _docNumber, _email, _phone, _password, _confirm]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _refresh() => setState(() {});

  /// «Crear cuenta» is enabled only when every field is valid and the box is checked.
  bool get _canSubmit =>
      !_loading &&
      _acceptTerms &&
      _docType != null &&
      Validators.fullName(_fullName.text) == null &&
      Validators.docNumber(_docNumber.text) == null &&
      Validators.email(_email.text) == null &&
      Validators.phone(_phone.text) == null &&
      Validators.password(_password.text) == null &&
      Validators.confirmPassword(_confirm.text, _password.text) == null;

  void _clearServerError(String field) {
    if (_serverErrors.containsKey(field)) {
      setState(() => _serverErrors = Map.of(_serverErrors)..remove(field));
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || !_canSubmit) return;

    setState(() {
      _loading = true;
      _serverErrors = {};
      _generalError = null;
    });

    final phone = Validators.cleanPhone(_phone.text);
    try {
      await ref.read(authControllerProvider.notifier).register(
            RegisterData(
              fullName: _fullName.text.trim(),
              docType: _docType!,
              docNumber: _docNumber.text.trim().toUpperCase(),
              email: _email.text.trim().toLowerCase(),
              phone: phone.isEmpty ? null : phone,
              password: _password.text,
            ),
          );
      // The router sends the user to Inicio when the session opens.
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _serverErrors = error.fieldErrors;
        // When the error belongs to a field it is shown there; otherwise on top.
        _generalError = error.fieldErrors.isEmpty ? error.message : null;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: AutofillGroup(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (_generalError != null) ...[
                  MessageBanner(
                    message: _generalError!,
                    actionLabel: 'Reintentar',
                    onAction: _canSubmit ? _submit : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                AppTextField(
                  label: 'Nombre completo',
                  controller: _fullName,
                  validator: Validators.fullName,
                  errorText: _serverErrors['full_name'],
                  onChanged: (_) => _clearServerError('full_name'),
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                ),
                const SizedBox(height: AppSpacing.md),
                AppDropdown<String>(
                  label: 'Tipo de documento',
                  options: docTypeLabels,
                  value: _docType,
                  validator: (value) =>
                      value == null ? 'Elige el tipo de documento.' : null,
                  onChanged: (value) => setState(() => _docType = value),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Número de documento',
                  controller: _docNumber,
                  validator: Validators.docNumber,
                  errorText: _serverErrors['doc_number'],
                  onChanged: (_) => _clearServerError('doc_number'),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                    UpperCaseTextFormatter(),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Correo electrónico',
                  controller: _email,
                  validator: Validators.email,
                  errorText: _serverErrors['email'],
                  onChanged: (_) => _clearServerError('email'),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Teléfono (opcional)',
                  controller: _phone,
                  validator: Validators.phone,
                  errorText: _serverErrors['phone'],
                  onChanged: (_) => _clearServerError('phone'),
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Contraseña',
                  controller: _password,
                  validator: Validators.password,
                  errorText: _serverErrors['password'],
                  onChanged: (_) => _clearServerError('password'),
                  helperText: 'Mínimo 8 caracteres.',
                  obscure: true,
                  autofillHints: const [AutofillHints.newPassword],
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Confirmar contraseña',
                  controller: _confirm,
                  validator: (value) => Validators.confirmPassword(value, _password.text),
                  obscure: true,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: AppSpacing.sm),
                _ConsentRow(
                  value: _acceptTerms,
                  onChanged: (value) => setState(() => _acceptTerms = value),
                  errorText: _serverErrors['accept_terms'],
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: 'Crear cuenta',
                  loading: _loading,
                  onPressed: _canSubmit ? _submit : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConsentRow extends StatelessWidget {
  const _ConsentRow({required this.value, required this.onChanged, this.errorText});

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(value: value, onChanged: (checked) => onChanged(checked ?? false)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => onChanged(!value),
                    child: const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text('Acepto el tratamiento de mis datos personales'),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () => showPrivacyPolicyDialog(context),
                    child: const Text('Ver política completa'),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (errorText != null)
          Text(errorText!, style: const TextStyle(color: AppColors.error)),
      ],
    );
  }
}
