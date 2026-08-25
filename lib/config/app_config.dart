enum AppEnvironment { development, production }

/// Configuration centralisée de l'application.
///
/// L'environnement et l'URL de l'API sont fournis à la compilation via
/// `--dart-define`, jamais codés en dur dans le reste du code :
///
/// ```
/// flutter run --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://api.example.com
/// ```
class AppConfig {
  const AppConfig({required this.environment, required this.apiBaseUrl});

  final AppEnvironment environment;
  final String apiBaseUrl;

  static const _envName = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static const current = AppConfig(
    environment: _envName == 'production'
        ? AppEnvironment.production
        : AppEnvironment.development,
    apiBaseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8000/api',
    ),
  );

  bool get isProduction => environment == AppEnvironment.production;
  bool get isDevelopment => environment == AppEnvironment.development;
}
