import 'dart:io';
import 'package:dio/dio.dart';
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
  /// [photo] : pièce jointe optionnelle (école) à l'annonce.
  Future<void> publierAnnonce({
    required String title,
    required String body,
    required String category,
    required List<Map<String, dynamic>> targets,
    File? photo,
  }) async {
    final data = FormData.fromMap({
      'title': title,
      'body': body,
      'category': category,
      'targets': targets,
      if (photo != null) 'photo': await MultipartFile.fromFile(photo.path, filename: photo.path.split('/').last),
    });
    await apiService.postMultipart('/admin/announcements', data);
  }

  /// Masque l'annonce de ma propre liste — réversible, sans effet pour les
  /// autres destinataires (docs/PRODUCT_ARCHITECTURE.md).
  Future<void> archiverAnnonce(int id) async {
    await apiService.post('/admin/announcements/$id/archive');
  }

  Future<void> desarchiverAnnonce(int id) async {
    await apiService.delete('/admin/announcements/$id/archive');
  }

  /// Suppression réelle — réservée à l'auteur ou à qui peut publier
  /// (l'API renvoie 403 sinon).
  Future<void> supprimerAnnonce(int id) async {
    await apiService.delete('/admin/announcements/$id');
  }
}
