import '../models/notification_app.dart';
import 'api_service.dart';

/// Historique des notifications (/api/v1/notifications). Nommé
/// différemment de NotificationService (Firebase/local) pour éviter toute
/// confusion entre les deux responsabilités.
class NotificationApiService {
  Future<({List<NotificationApp> notifications, int nonLues})> getNotifications() async {
    final data = await apiService.get('/notifications');
    final page = data['data'] as Map<String, dynamic>;
    final items = (page['data'] as List).map((e) => NotificationApp.fromJson(e as Map<String, dynamic>)).toList();
    return (notifications: items, nonLues: data['unread_count'] as int? ?? 0);
  }

  Future<void> marquerLue(String id) async {
    await apiService.patch('/notifications/$id/read');
  }

  Future<void> toutMarquerLu() async {
    await apiService.patch('/notifications/read-all');
  }
}
