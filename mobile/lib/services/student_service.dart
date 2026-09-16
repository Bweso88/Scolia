import '../models/student.dart';
import 'api_service.dart';

/// Liste des élèves de l'école pour le personnel (/api/v1/admin/students),
/// utilisée dans les formulaires (nouvelle remarque, absence, note...).
class StudentService {
  Future<List<Student>> getEleves({int? schoolClassId}) async {
    final data = await apiService.get('/admin/students', params: schoolClassId != null ? {'school_class_id': schoolClassId} : null);
    return (data['data'] as List).map((e) => Student.fromJson(e as Map<String, dynamic>)).toList();
  }
}
