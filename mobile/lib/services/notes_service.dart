import '../models/note.dart';
import '../models/periode.dart';
import 'api_service.dart';

/// Actions du personnel sur les notes (/api/v1/admin/grades et
/// /api/v1/admin/grading-periods). Côté parent, la lecture passe par
/// ChildrenService (/api/v1/children/{id}/grades).
class NotesService {
  Future<List<Periode>> getPeriodes() async {
    final data = await apiService.get('/admin/grading-periods');
    return (data['data'] as List).map((e) => Periode.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saisirNote(Map<String, dynamic> corps) async {
    await apiService.post('/admin/grades', body: corps);
  }

  /// Notes déjà saisies pour une classe (vue personnel) — filtrable par
  /// devoir pour voir qui a déjà été noté sur un devoir précis.
  Future<List<Note>> getNotesDeLaClasse({int? schoolClassId, int? homeworkId}) async {
    final data = await apiService.get('/admin/grades', params: {
      if (schoolClassId != null) 'school_class_id': schoolClassId,
      if (homeworkId != null) 'homework_id': homeworkId,
    });
    return (data['data'] as List).map((e) => Note.fromJson(e as Map<String, dynamic>)).toList();
  }
}
