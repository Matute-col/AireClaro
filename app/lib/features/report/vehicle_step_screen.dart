import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/router.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/form_fields.dart';
import '../../shared/widgets/step_progress.dart';
import 'report_draft.dart';

/// Screen 06 · Paso 2 de 4: Datos del vehículo (US-06, RF-04, RF-05).
class VehicleStepScreen extends ConsumerStatefulWidget {
  const VehicleStepScreen({super.key});

  @override
  ConsumerState<VehicleStepScreen> createState() => _VehicleStepScreenState();
}

class _VehicleStepScreenState extends ConsumerState<VehicleStepScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ReportDraft _initial = ref.read(reportDraftProvider);
  late final _plate = TextEditingController(text: _initial.plate);
  late final _description = TextEditingController(text: _initial.description);

  ReportDraftController get _draft => ref.read(reportDraftProvider.notifier);

  @override
  void dispose() {
    _plate.dispose();
    _description.dispose();
    super.dispose();
  }

  bool _canContinue(ReportDraft draft) =>
      draft.vehicleType != null &&
      draft.smokeColor != null &&
      Validators.plate(draft.plate) == null;

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    context.push(Routes.reportLocation);
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(reportDraftProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo reporte')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const StepProgress(step: 2),
              const SizedBox(height: AppSpacing.lg),
              Text('Datos del vehículo', style: textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              AppDropdown<String>(
                label: 'Tipo de vehículo',
                options: vehicleTypeLabels,
                value: draft.vehicleType,
                validator: (value) => value == null ? 'Elige el tipo de vehículo.' : null,
                onChanged: (value) {
                  if (value != null) _draft.updateVehicle(vehicleType: value);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Placa',
                controller: _plate,
                hintText: 'ABC123',
                helperText: 'Carro: ABC123 · Moto: ABC12D',
                validator: Validators.plate,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  LengthLimitingTextInputFormatter(6),
                  UpperCaseTextFormatter(),
                ],
                onChanged: (value) => _draft.updateVehicle(plate: value),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Color del humo', style: textTheme.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final entry in smokeColorLabels.entries)
                    ChoiceChip(
                      label: Text(entry.value),
                      selected: draft.smokeColor == entry.key,
                      onSelected: (_) => _draft.updateVehicle(smokeColor: entry.key),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _description,
                maxLength: maxDescriptionLength,
                maxLines: 4,
                minLines: 2,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: AppColors.onField),
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'Ej.: humo negro denso al arrancar en el semáforo',
                  alignLabelWithHint: true,
                ),
                onChanged: (value) => _draft.updateVehicle(description: value),
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
                      label: 'Siguiente',
                      onPressed: _canContinue(draft) ? _next : null,
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
