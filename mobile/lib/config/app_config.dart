class AppConfig {
  /// Point d'entrée unique de l'API Laravel. Le tenant (l'école) n'est
  /// jamais choisi côté client : il est résolu par le serveur à partir des
  /// identifiants de connexion (docs/PRODUCT_ARCHITECTURE.md §9).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://votre-domaine.com/api/v1',
  );

  static const int itemsParPage = 20;
  static const int timeoutSecondes = 30;
}
