import '../models/school_class_admin.dart';
import '../models/school_year_ref.dart';
import '../models/student_guardian.dart';
import '../models/teacher_admin.dart';
import 'api_service.dart';

/// Gestion de l'établissement par la direction (classes, professeurs,
/// parents/tuteurs) — équivalent mobile du panel web Filament.
class GestionService {
  Future<List<SchoolYearRef>> getAnneesScolaires() async {
    final data = await apiService.get('/admin/school-years');
    return (data['data'] as List).map((e) => SchoolYearRef.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<SchoolClassAdmin>> getClasses() async {
    final data = await apiService.get('/admin/school-classes');
    return (data['data'] as List).map((e) => SchoolClassAdmin.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> creerClasse(Map<String, dynamic> corps) async {
    await apiService.post('/admin/school-classes', body: corps);
  }

  Future<void> modifierClasse(int id, Map<String, dynamic> corps) async {
    await apiService.patch('/admin/school-classes/$id', body: corps);
  }

  Future<void> supprimerClasse(int id) async {
    await apiService.delete('/admin/school-classes/$id');
  }

  Future<List<TeacherAdmin>> getProfesseurs() async {
    final data = await apiService.get('/admin/teachers');
    return (data['data'] as List).map((e) => TeacherAdmin.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> creerProfesseur(Map<String, dynamic> corps) async {
    await apiService.post('/admin/teachers', body: corps);
  }

  Future<void> modifierProfesseur(int id, Map<String, dynamic> corps) async {
    await apiService.patch('/admin/teachers/$id', body: corps);
  }

  Future<void> supprimerProfesseur(int id) async {
    await apiService.delete('/admin/teachers/$id');
  }

  Future<List<StudentGuardianAdmin>> getParents(int studentId) async {
    final data = await apiService.get('/admin/students/$studentId/guardians');
    return (data['data'] as List).map((e) => StudentGuardianAdmin.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> lierParent(int studentId, Map<String, dynamic> corps) async {
    await apiService.post('/admin/students/$studentId/guardians', body: corps);
  }

  Future<void> delierParent(int studentId, int guardianId) async {
    await apiService.delete('/admin/students/$studentId/guardians/$guardianId');
  }
}
