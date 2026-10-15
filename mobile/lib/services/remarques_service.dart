import '../models/remarque.dart';
import 'api_service.dart';

/// Actions du personnel sur le comportement (/api/v1/admin/behavior-observations).
/// Côté parent, la lecture passe par ChildrenService (/api/v1/children/*).
class RemarquesService {
  Future<List<Remarque>> getRemarques({int? studentId}) async {
    final data = await apiService.get('/admin/behavior-observations', params: studentId != null ? {'student_id': studentId} : null);
    return (data['data'] as List).map((e) => Remarque.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> creerRemarque(Map<String, dynamic> corps) async {
    await apiService.post('/admin/behavior-observations', body: corps);
  }

  /// Masque l'observation de ma propre liste — réversible, sans effet pour
  /// les autres (parent comme enseignant peuvent le faire).
  Future<void> archiverRemarque(int id) async {
    await apiService.post('/admin/behavior-observations/$id/archive');
  }

  Future<void> desarchiverRemarque(int id) async {
    await apiService.delete('/admin/behavior-observations/$id/archive');
  }

  /// Suppression réelle — réservée à son auteur ou à l'administration
  /// (l'API renvoie 403 sinon).
  Future<void> supprimerRemarque(int id) async {
    await apiService.delete('/admin/behavior-observations/$id');
  }
}
