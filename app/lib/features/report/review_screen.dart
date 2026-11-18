import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/api_error.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/report_mini_map.dart';
import '../../shared/widgets/states.dart';
import '../history/reports_list_controller.dart';
import 'authorities_repository.dart';
import 'evidence_step_screen.dart';
import 'location_step_screen.dart';
import 'report_draft.dart';
import 'reports_repository.dart';

/// Screen 09 · Revisión (US-09, RF-07): summary, suggested authority with «Cambiar»
/// and «Generar solicitud», which creates the report (POST /reports).
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  bool _sending = false;
  double _progress = 0;
  String? _error;
  bool _canRetry = false;

  /// «Editar» goes back to that step: the steps are stacked in order
  /// (evidence, vehicle, location, requester, review).
  void _editStep(int step) {
    final navigator = Navigator.of(context);
    for (var i = 0; i < 5 - step; i++) {
      navigator.pop();
    }
  }

  Future<void> _chooseAuthority(List<Authority> authorities, int? current) async {
    final chosen = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Autoridad destinataria'),
        children: [
          RadioGroup<int>(
            groupValue: current,
            onChanged: (value) => Navigator.of(context).pop(value),
            child: Column(
              children: [
                for (final authority in authorities)
                  RadioListTile<int>(value: authority.id, title: Text(authority.name)),
              ],
            ),
          ),
        ],
      ),
    );
    if (chosen != null) ref.read(reportDraftProvider.notifier).chooseAuthority(chosen);
  }

  Future<void> _submit() async {
    setState(() {
      _sending = true;
      _progress = 0;
      _error = null;
    });
    try {
      final reportId = await ref.read(reportsRepositoryProvider).create(
            ref.read(reportDraftProvider),
            onProgress: (value) {
              if (mounted) setState(() => _progress = value);
            },
          );
      if (!mounted) return;
      // The messenger lives above the routes, so the message stays after navigating.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reporte creado.')),
      );
      final draft = ref.read(reportDraftProvider.notifier);
      final router = GoRouter.of(context);
      // «Mis reportes» and the count on Inicio must include the new report.
      ref.invalidate(reportsListProvider);
      ref.invalidate(reportsCountProvider);
      // Inicio, with the preview of the new request on top («Atrás» returns to Inicio).
      router.go(Routes.home);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        router.push(Routes.reportPreview(reportId, justCreated: true));
        draft.reset(); // the flow screens are gone: clear the draft (no drafts, docs/06)
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _canRetry = error.isNetworkError || (error.statusCode ?? 0) >= 500;
        _error = _describe(error);
      });
    }
  }

  /// Field errors belong to earlier steps: list them so the user knows what to fix.
  String _describe(ApiException error) {
    if (error.fieldErrors.isEmpty) return error.message;
    return '${error.message}\n${error.fieldErrors.values.map((m) => '• $m').join('\n')}';
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(reportDraftProvider);
    final authorities = ref.watch(authoritiesProvider);
    final percent = (_progress * 100).round();

    if (!draft.hasLocation || draft.occurredAt == null) {
      // The draft was just cleared after creating the report.
      return const Scaffold(body: SizedBox.shrink());
    }

    return PopScope(
      canPop: !_sending,
      child: Scaffold(
        appBar: AppBar(title: const Text('Revisa tu reporte')),
        body: LoadingOverlay(
          loading: _sending,
          message: percent < 100 ? 'Enviando reporte… $percent %' : 'Guardando reporte…',
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (_error != null) ...[
                  MessageBanner(
                    message: _error!,
                    actionLabel: _canRetry ? 'Reintentar' : null,
                    onAction: _canRetry ? _submit : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                _Section(
                  title: 'Evidencia',
                  onEdit: () => _editStep(1),
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [for (final f in draft.evidence) EvidenceThumbnail(file: f)],
                  ),
                ),
                _Section(
                  title: 'Vehículo',
                  onEdit: () => _editStep(2),
                  child: _Lines([
                    ('Tipo', vehicleTypeLabels[draft.vehicleType] ?? '—'),
                    ('Placa', draft.plate),
                    ('Color del humo', smokeColorLabels[draft.smokeColor] ?? '—'),
                    if (draft.description.trim().isNotEmpty)
                      ('Descripción', draft.description.trim()),
                  ]),
                ),
                _Section(
                  title: 'Ubicación y hora',
                  onEdit: () => _editStep(3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ReportMiniMap(point: LatLng(draft.lat!, draft.lng!)),
                      const SizedBox(height: AppSpacing.sm),
                      _Lines([
                        ('Dirección', draft.address ?? 'Sin dirección aproximada'),
                        ('Fecha y hora', formatReportDate(draft.occurredAt!)),
                      ]),
                    ],
                  ),
                ),
                _Section(
                  title: 'Peticionario',
                  onEdit: () => _editStep(4),
                  child: _Lines([
                    ('Nombre', draft.requester.name),
                    ('Documento', '${draft.requester.docType ?? ''} ${draft.requester.docNumber}'),
                    ('Correo', draft.requester.email),
                    if (draft.requester.phone.trim().isNotEmpty) ('Teléfono', draft.requester.phone),
                  ]),
                ),
                _AuthoritySection(
                  draft: draft,
                  authorities: authorities,
                  onChoose: (list) => _chooseAuthority(list, draft.authorityId),
                  onRetry: () => ref.invalidate(authoritiesProvider),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'AireClaro no mide emisiones ni impone sanciones. Genera una solicitud con la '
                  'evidencia que tú aportas.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: 'Generar solicitud',
                  icon: Icons.description_outlined,
                  onPressed: draft.authorityId == null || _sending ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthoritySection extends StatelessWidget {
  const _AuthoritySection({
    required this.draft,
    required this.authorities,
    required this.onChoose,
    required this.onRetry,
  });

  final ReportDraft draft;
  final AsyncValue<List<Authority>> authorities;
  final void Function(List<Authority>) onChoose;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return authorities.when(
      loading: () => const _Section(
        title: 'Autoridad destinataria',
        child: Text('Cargando autoridades…'),
      ),
      error: (error, _) => _Section(
        title: 'Autoridad destinataria',
        child: MessageBanner(
          message: toApiException(error).message,
          actionLabel: 'Reintentar',
          onAction: onRetry,
        ),
      ),
      data: (list) {
        final selected = list.where((a) => a.id == draft.authorityId).firstOrNull;
        final isSuggestion =
            draft.chosenAuthorityId == null && draft.suggestedAuthorityId == selected?.id;
        return _Section(
          title: 'Autoridad destinataria',
          action: TextButton(
            onPressed: () => onChoose(list),
            child: Text(selected == null ? 'Elegir' : 'Cambiar'),
          ),
          child: selected == null
              ? const MessageBanner(
                  message: 'No pudimos sugerir una autoridad para este lugar. Elígela para continuar.',
                  isError: false,
                )
              : _Lines([
                  (selected.name, isSuggestion ? 'Sugerida según la ubicación' : 'Elegida por ti'),
                ]),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.onEdit, this.action});

  final String title;
  final Widget child;
  final VoidCallback? onEdit;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
                ?action,
                if (onEdit != null) TextButton(onPressed: onEdit, child: const Text('Editar')),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      ),
    );
  }
}

/// Label/value pairs, one per line.
class _Lines extends StatelessWidget {
  const _Lines(this.lines);

  final List<(String, String)> lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, value) in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text.rich(TextSpan(children: [
              TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
              TextSpan(text: value),
            ])),
          ),
      ],
    );
  }
}
