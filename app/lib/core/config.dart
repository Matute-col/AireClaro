/// Build-time configuration.
///
/// The API URL is passed when running or building the app, never hard-coded:
/// `flutter run --dart-define=API_BASE_URL=http://localhost:3000/api`
class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static bool get hasApiBaseUrl => apiBaseUrl.isNotEmpty;
}
