import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

class NotificationService {
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  /// Branché depuis app.dart pour rafraîchir le badge de la cloche
  /// (NotificationsProvider) dès qu'un message arrive au premier plan,
  /// sans coupler ce service (statique, sans accès au Provider) au reste
  /// de l'arbre de widgets.
  static void Function()? onMessageReceived;

  /// Branché depuis app.dart pour renvoyer au backend un token FCM
  /// renouvelé par le système (l'ancien devient invalide, la notification
  /// ne partirait plus vers cet appareil sinon).
  static void Function(String token)? onTokenRefreshed;

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
      // Requis sur Android 13+ (et affiché à l'utilisateur sur iOS) :
      // sans cette autorisation explicite, aucune notification ne
      // s'affiche même si le message FCM est bien reçu par l'appareil.
      await FirebaseMessaging.instance.requestPermission();
      FirebaseMessaging.onMessage.listen(_afficherNotifLocale);
      FirebaseMessaging.onMessageOpenedApp.listen(_gererOuverture);
      FirebaseMessaging.onBackgroundMessage(_gererEnArrierePlan);
      FirebaseMessaging.instance.onTokenRefresh.listen((token) => onTokenRefreshed?.call(token));
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
    onMessageReceived?.call();
  }

  static void _gererOuverture(RemoteMessage message) {
    // Navigation selon message.data['type']
  }
}

@pragma('vm:entry-point')
Future<void> _gererEnArrierePlan(RemoteMessage message) async {
  // Traitement en arrière-plan
}
