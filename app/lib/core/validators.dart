/// Form validators. They follow the same rules as the API (backend/src/modules/*/*.schema.js)
/// so the user sees the error before sending. Each returns null when the value is valid.
class Validators {
  Validators._();

  static final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _docNumberRegex = RegExp(r'^[A-Z0-9]{4,20}$');
  static final _phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');

  static String? required(String? value, {String message = 'Este campo es obligatorio.'}) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'El correo es obligatorio.';
    if (!_emailRegex.hasMatch(text)) return 'Escribe un correo electrónico válido.';
    return null;
  }

  static String? fullName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'El nombre completo es obligatorio.';
    if (text.length < 2) return 'El nombre debe tener al menos 2 caracteres.';
    if (text.length > 100) return 'El nombre puede tener máximo 100 caracteres.';
    return null;
  }

  static String? docNumber(String? value) {
    final text = value?.trim().toUpperCase() ?? '';
    if (text.isEmpty) return 'El número de documento es obligatorio.';
    if (!_docNumberRegex.hasMatch(text)) {
      return 'Entre 4 y 20 letras o números, sin espacios ni puntos.';
    }
    return null;
  }

  /// Optional: empty is valid. Spaces and dashes are ignored, like in the API.
  static String? phone(String? value) {
    final text = cleanPhone(value);
    if (text.isEmpty) return null;
    if (!_phoneRegex.hasMatch(text)) return 'El teléfono debe tener entre 7 y 15 dígitos.';
    return null;
  }

  static String cleanPhone(String? value) => (value ?? '').replaceAll(RegExp(r'[\s-]'), '');

  static final _plateRegex = RegExp(r'^([A-Z]{3}\d{3}|[A-Z]{3}\d{2}[A-Z])$');

  /// Plate «ABC123» (cars, buses, trucks) or «ABC12D» (motorcycles), like the API.
  static String? plate(String? value) {
    final text = normalizePlate(value);
    if (text.isEmpty) return 'La placa es obligatoria.';
    if (!_plateRegex.hasMatch(text)) return 'La placa debe tener el formato ABC123 o ABC12D.';
    return null;
  }

  /// Uppercase, without spaces or dashes.
  static String normalizePlate(String? value) =>
      (value ?? '').toUpperCase().replaceAll(RegExp(r'[\s-]'), '');

  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'La contraseña es obligatoria.';
    if (text.length < 8) return 'La contraseña debe tener al menos 8 caracteres.';
    if (text.length > 72) return 'La contraseña es demasiado larga (máximo 72 caracteres).';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirma tu contraseña.';
    if (value != password) return 'Las contraseñas no coinciden.';
    return null;
  }
}
