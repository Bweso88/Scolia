import 'api_service.dart';

/// Préférences de notifications par catégorie/canal
/// (/api/v1/notification-preferences, docs/PRODUCT_ARCHITECTURE.md §16).
/// Une catégorie sans préférence explicite est active par défaut.
class NotificationPreferenceService {
  Future<Map<String, bool>> getPreferences() async {
    final data = await apiService.get('/notification-preferences');
    final prefs = <String, bool>{};
    for (final p in (data['data'] as List)) {
      prefs['${p['category']}_${p['channel']}'] = p['is_enabled'] as bool;
    }
    return prefs;
  }

  Future<void> definir(String categorie, bool actif, {String canal = 'push'}) async {
    await apiService.patch('/notification-preferences', body: {
      'preferences': [
        {'category': categorie, 'channel': canal, 'is_enabled': actif},
      ],
    });
  }
}
