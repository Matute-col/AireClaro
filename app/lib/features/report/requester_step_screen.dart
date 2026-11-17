import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/router.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/form_fields.dart';
import '../../shared/widgets/states.dart';
import '../../shared/widgets/step_progress.dart';
import '../auth/auth_controller.dart';
import '../auth/user.dart';
import 'report_draft.dart';

/// Screen 08 · Paso 4 de 4: Datos del peticionario (US-08).
/// Prefilled from the profile and editable. There is no anonymous option.
class RequesterStepScreen extends ConsumerStatefulWidget {
  const RequesterStepScreen({super.key});

  @override
  ConsumerState<RequesterStepScreen> createState() => _RequesterStepScreenState();
}

class _RequesterStepScreenState extends ConsumerState<RequesterStepScreen> {
  final _formKey = GlobalKey<FormState>();
  late final RequesterData _initial;
  late final TextEditingController _name;
  late final TextEditingController _docNumber;
  late final TextEditingController _email;
  late final TextEditingController _phone;

  ReportDraftController get _draft => ref.read(reportDraftProvider.notifier);

  @override
  void initState() {
    super.initState();
    // Prefill from the profile only the first time; afterwards keep what the user typed.
    final user = ref.read(authControllerProvider).user;
    final current = ref.read(reportDraftProvider).requester;
    _initial = current.isEmpty && user != null ? RequesterData.fromUser(user) : current;
    // Providers cannot change while the tree is building: save it right after.
    Future.microtask(() => _draft.prefillRequester(user));
    _name = TextEditingController(text: _initial.name);
    _docNumber = TextEditingController(text: _initial.docNumber);
    _email = TextEditingController(text: _initial.email);
    _phone = TextEditingController(text: _initial.phone);
  }

  @override
  void dispose() {
    for (final controller in [_name, _docNumber, _email, _phone]) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _isValid(RequesterData r) =>
      r.docType != null &&
      Validators.fullName(r.name) == null &&
      Validators.docNumber(r.docNumber) == null &&
      Validators.email(r.email) == null &&
      Validators.phone(r.phone) == null;

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    context.push(Routes.reportReview);
  }

  @override
  Widget build(BuildContext context) {
    final requester = ref.watch(reportDraftProvider.select((d) => d.requester));

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo reporte')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const StepProgress(step: 4),
              const SizedBox(height: AppSpacing.lg),
              Text('Datos del peticionario', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              const MessageBanner(
                message: 'Estos datos se usan para generar tu solicitud.',
                isError: false,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Nombre completo',
                controller: _name,
                validator: Validators.fullName,
                textCapitalization: TextCapitalization.words,
                onChanged: (value) => _draft.updateRequester(name: value),
              ),
              const SizedBox(height: AppSpacing.md),
              AppDropdown<String>(
                label: 'Tipo de documento',
                options: docTypeLabels,
                value: requester.docType,
                validator: (value) => value == null ? 'Elige el tipo de documento.' : null,
                onChanged: (value) {
                  if (value != null) _draft.updateRequester(docType: value);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Número de documento',
                controller: _docNumber,
                validator: Validators.docNumber,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  UpperCaseTextFormatter(),
                ],
                onChanged: (value) => _draft.updateRequester(docNumber: value),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Correo',
                controller: _email,
                validator: Validators.email,
                keyboardType: TextInputType.emailAddress,
                helperText: 'Aquí te responderá la autoridad.',
                onChanged: (value) => _draft.updateRequester(email: value),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Teléfono (opcional)',
                controller: _phone,
                validator: Validators.phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                onChanged: (value) => _draft.updateRequester(phone: value),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(label: 'Atrás', onPressed: () => context.pop()),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Revisar reporte',
                      onPressed: _isValid(requester) ? _next : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
