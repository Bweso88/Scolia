import 'package:flutter/foundation.dart';
import '../services/notification_service_api.dart';

/// Nombre de notifications non lues, affiché en badge sur la cloche
/// (écran d'accueil). Rafraîchi à la connexion, à l'ouverture de l'écran
/// d'accueil et à la réception d'un message FCM au premier plan (voir
/// NotificationService.onMessageReceived).
class NotificationsProvider extends ChangeNotifier {
  final _api = NotificationApiService();

  int nonLues = 0;

  Future<void> charger() async {
    try {
      final resultat = await _api.getNotifications();
      nonLues = resultat.nonLues;
      notifyListeners();
    } catch (_) {
      // Le badge reste simplement inchangé en cas d'erreur réseau.
    }
  }
}
