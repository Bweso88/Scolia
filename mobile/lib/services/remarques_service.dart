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
}
