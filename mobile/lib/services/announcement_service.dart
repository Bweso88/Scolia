import '../models/announcement.dart';
import 'api_service.dart';

/// Publication d'annonces par le personnel (/api/v1/admin/announcements).
/// Côté parent, la lecture passe par ChildrenService.
class AnnouncementService {
  Future<List<Announcement>> getAnnonces() async {
    final data = await apiService.get('/admin/announcements');
    return (data['data'] as List).map((e) => Announcement.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// [targets] : liste de {'target_type': 'all'|'school_class'|'user', 'target_id': int?}
  Future<void> publierAnnonce({
    required String title,
    required String body,
    required String category,
    required List<Map<String, dynamic>> targets,
  }) async {
    await apiService.post('/admin/announcements', body: {
      'title': title,
      'body': body,
      'category': category,
      'targets': targets,
    });
  }
}
