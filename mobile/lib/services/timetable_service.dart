import '../models/timetable_slot.dart';
import 'api_service.dart';

/// Emploi du temps côté personnel (/api/v1/admin/timetable-slots), filtré sur
/// la classe de l'enseignant — même patron que HomeworkService.
class TimetableService {
  Future<List<TimetableSlot>> getEmploiDuTemps({int? schoolClassId}) async {
    final data = await apiService.get('/admin/timetable-slots', params: schoolClassId != null ? {'school_class_id': schoolClassId} : null);
    return (data['data'] as List).map((e) => TimetableSlot.fromJson(e as Map<String, dynamic>)).toList();
  }
}
