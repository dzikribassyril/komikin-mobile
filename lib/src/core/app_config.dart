class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'KOMIKIN_API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
}
