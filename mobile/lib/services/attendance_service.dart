import '../models/attendance_record.dart';
import 'api_service.dart';

/// Absences/retards (/api/v1/admin/attendance-records). Côté parent, la
/// lecture passe par ChildrenService ; la justification et la saisie sont
/// communes aux deux profils et vivent ici.
class AttendanceService {
  Future<List<AttendanceRecord>> getAbsences({int? studentId}) async {
    final data = await apiService.get('/admin/attendance-records', params: studentId != null ? {'student_id': studentId} : null);
    return (data['data'] as List).map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saisirAbsence(Map<String, dynamic> corps) async {
    await apiService.post('/admin/attendance-records', body: corps);
  }

  /// Le parent justifie une absence directement depuis l'app
  /// (docs/PRODUCT_ARCHITECTURE.md §6, module Absences).
  Future<void> justifier(int attendanceRecordId, String explication) async {
    await apiService.post('/admin/attendance-records/$attendanceRecordId/justify', body: {'explanation': explication});
  }

  Future<void> validerJustification(int attendanceRecordId, {required bool approuve}) async {
    await apiService.patch('/admin/attendance-records/$attendanceRecordId/justification', body: {
      'status': approuve ? 'approved' : 'rejected',
    });
  }
}
