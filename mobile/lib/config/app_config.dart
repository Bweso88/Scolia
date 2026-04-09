class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://votre-domaine.com/api',
  );

  static const String ecoleSlug = String.fromEnvironment(
    'ECOLE_SLUG',
    defaultValue: 'ecole-exemple',
  );

  static const int itemsParPage = 20;
  static const int timeoutSecondes = 30;
}
