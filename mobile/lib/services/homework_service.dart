import '../models/homework.dart';
import 'api_service.dart';

/// Actions du personnel sur les devoirs (/api/v1/admin/homeworks). Côté
/// parent, la lecture passe par ChildrenService (/api/v1/children/*).
class HomeworkService {
  Future<List<Homework>> getDevoirs({int? schoolClassId}) async {
    final data = await apiService.get('/admin/homeworks', params: schoolClassId != null ? {'school_class_id': schoolClassId} : null);
    return (data['data'] as List).map((e) => Homework.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> publierDevoir(Map<String, dynamic> corps) async {
    await apiService.post('/admin/homeworks', body: corps);
  }
}
