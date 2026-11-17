import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/api_error.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/form_fields.dart';
import '../../shared/widgets/states.dart';
import '../auth/auth_controller.dart';
import '../auth/user.dart';
import 'profile_repository.dart';

/// Edit profile: name, document and phone. The email is shown but cannot be edited.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final User _user = ref.read(authControllerProvider).user!;
  late final _fullName = TextEditingController(text: _user.fullName);
  late final _docNumber = TextEditingController(text: _user.docNumber);
  late final _phone = TextEditingController(text: _user.phone ?? '');
  late final _email = TextEditingController(text: _user.email);
  late String? _docType = docTypeLabels.containsKey(_user.docType) ? _user.docType : null;
  bool _loading = false;
  Map<String, String> _serverErrors = {};
  String? _generalError;

  @override
  void initState() {
    super.initState();
    for (final controller in [_fullName, _docNumber, _phone]) {
      controller.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    for (final controller in [_fullName, _docNumber, _phone, _email]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _refresh() => setState(() {});

  bool get _canSave =>
      !_loading &&
      _docType != null &&
      Validators.fullName(_fullName.text) == null &&
      Validators.docNumber(_docNumber.text) == null &&
      Validators.phone(_phone.text) == null;

  void _clearServerError(String field) {
    if (_serverErrors.containsKey(field)) {
      setState(() => _serverErrors = Map.of(_serverErrors)..remove(field));
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || !_canSave) return;

    setState(() {
      _loading = true;
      _serverErrors = {};
      _generalError = null;
    });
    final phone = Validators.cleanPhone(_phone.text);
    try {
      final updated = await ref.read(profileRepositoryProvider).update(
            ProfileData(
              fullName: _fullName.text.trim(),
              docType: _docType!,
              docNumber: _docNumber.text.trim().toUpperCase(),
              phone: phone.isEmpty ? null : phone,
            ),
          );
      ref.read(authControllerProvider.notifier).updateUser(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado.')),
      );
      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _serverErrors = error.fieldErrors;
        _generalError = error.fieldErrors.isEmpty ? error.message : null;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              if (_generalError != null) ...[
                MessageBanner(
                  message: _generalError!,
                  actionLabel: 'Reintentar',
                  onAction: _canSave ? _save : null,
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
              ),
              const SizedBox(height: AppSpacing.md),
              AppDropdown<String>(
                label: 'Tipo de documento',
                options: docTypeLabels,
                value: _docType,
                validator: (value) => value == null ? 'Elige el tipo de documento.' : null,
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
                label: 'Teléfono (opcional)',
                controller: _phone,
                validator: Validators.phone,
                errorText: _serverErrors['phone'],
                onChanged: (_) => _clearServerError('phone'),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                key: const Key('email-readonly'),
                label: 'Correo electrónico',
                controller: _email,
                helperText: 'El correo no se puede cambiar.',
                enabled: false,
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Guardar cambios',
                loading: _loading,
                onPressed: _canSave ? _save : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
