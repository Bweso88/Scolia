import '../models/student.dart';
import 'api_service.dart';

/// Liste des élèves de l'école pour le personnel (/api/v1/admin/students),
/// utilisée dans les formulaires (nouvelle remarque, absence, note...).
class StudentService {
  Future<List<Student>> getEleves({int? schoolClassId}) async {
    final data = await apiService.get('/admin/students', params: schoolClassId != null ? {'school_class_id': schoolClassId} : null);
    return (data['data'] as List).map((e) => Student.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> creerEleve(Map<String, dynamic> corps) async {
    await apiService.post('/admin/students', body: corps);
  }

  Future<void> modifierEleve(int id, Map<String, dynamic> corps) async {
    await apiService.patch('/admin/students/$id', body: corps);
  }

  Future<void> activerEleve(int id, bool actif) async {
    await apiService.patch('/admin/students/$id/activation', body: {'active': actif});
  }
}
