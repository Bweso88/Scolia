import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

class NotificationService {
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialiser() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios     = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Sans projet Firebase configuré, Firebase.initializeApp() a déjà
    // échoué silencieusement (voir main.dart) : ces appels lèveraient
    // alors une exception à chaque démarrage.
    try {
      FirebaseMessaging.onMessage.listen(_afficherNotifLocale);
      FirebaseMessaging.onMessageOpenedApp.listen(_gererOuverture);
      FirebaseMessaging.onBackgroundMessage(_gererEnArrierePlan);
    } catch (_) {}
  }

  static Future<String?> getToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  static Future<void> enregistrerToken(String token) async {
    await apiService.post('/devices', body: {
      'fcm_token': token,
      'platform': !kIsWeb && Platform.isIOS ? 'ios' : 'android',
    });
  }

  static Future<void> _afficherNotifLocale(RemoteMessage message) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'scolia_channel', 'Scolia',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      details,
    );
  }

  static void _gererOuverture(RemoteMessage message) {
    // Navigation selon message.data['type']
  }
}

@pragma('vm:entry-point')
Future<void> _gererEnArrierePlan(RemoteMessage message) async {
  // Traitement en arrière-plan
}
