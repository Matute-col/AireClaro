import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/api_error.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../core/validators.dart';
import '../../shared/widgets/buttons.dart';
import '../../shared/widgets/form_fields.dart';
import '../../shared/widgets/states.dart';
import 'auth_controller.dart';

/// Screen 02 · Iniciar sesión (UC-02, RF-01).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _isNetworkError = false;

  @override
  void initState() {
    super.initState();
    _email.addListener(_refresh);
    _password.addListener(_refresh);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  /// «Ingresar» is disabled while a field is empty or the email is invalid.
  bool get _canSubmit =>
      !_loading && Validators.email(_email.text) == null && _password.text.isNotEmpty;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || !_canSubmit) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).login(
            email: _email.text.trim().toLowerCase(),
            password: _password.text,
          );
      // The router sends the user to Inicio when the session opens.
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        // 401 brings the generic «Correo o contraseña incorrectos.» from the API.
        _error = error.message;
        _isNetworkError = error.isNetworkError;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionExpired = ref.watch(authControllerProvider).sessionExpired;

    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: AutofillGroup(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (sessionExpired && _error == null) ...[
                  const MessageBanner(
                    message: 'Tu sesión expiró. Inicia sesión de nuevo.',
                    isError: false,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (_error != null) ...[
                  MessageBanner(
                    message: _error!,
                    actionLabel: _isNetworkError ? 'Reintentar' : null,
                    onAction: _canSubmit ? _submit : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                AppTextField(
                  label: 'Correo electrónico',
                  controller: _email,
                  validator: Validators.email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Contraseña',
                  controller: _password,
                  validator: (value) => Validators.required(
                    value,
                    message: 'La contraseña es obligatoria.',
                  ),
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => _canSubmit ? _submit() : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: 'Ingresar',
                  loading: _loading,
                  onPressed: _canSubmit ? _submit : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: _loading ? null : () => context.pushReplacement(Routes.register),
                  child: const Text('¿No tienes cuenta? Crear cuenta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
