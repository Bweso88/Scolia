import '../models/announcement.dart';
import '../models/attendance_record.dart';
import '../models/homework.dart';
import '../models/note.dart';
import '../models/remarque.dart';
import '../models/student.dart';
import '../models/timetable_slot.dart';
import 'api_service.dart';

/// Regroupe les lectures parent sur les propres enfants du compte connecté
/// (/api/v1/children/*, docs/PRODUCT_ARCHITECTURE.md §9 et §12). Le
/// personnel de l'école peut aussi appeler ces routes ; elles restent
/// filtrées par la même policy que le back-office.
class ChildrenService {
  Future<List<Student>> getEnfants() async {
    final data = await apiService.get('/children');
    return (data['data'] as List).map((e) => Student.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Le tableau de bord agrège plusieurs sources ; chaque section est un
  /// tableau simple (pas de pagination) — voir ChildrenController::dashboard.
  Future<Map<String, dynamic>> getDashboard(int studentId) async {
    return apiService.get('/children/$studentId/dashboard');
  }

  Future<List<Homework>> getDevoirs(int studentId, {String range = 'week'}) async {
    final data = await apiService.get('/children/$studentId/homeworks', params: {'range': range});
    return (data['data'] as List).map((e) => Homework.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Remarque>> getComportement(int studentId) async {
    final data = await apiService.get('/children/$studentId/behavior');
    return (data['data'] as List).map((e) => Remarque.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<AttendanceRecord>> getAbsences(int studentId) async {
    final data = await apiService.get('/children/$studentId/attendance');
    return (data['data'] as List).map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<TimetableSlot>> getEmploiDuTemps(int studentId) async {
    final data = await apiService.get('/children/$studentId/timetable');
    return (data['data'] as List).map((e) => TimetableSlot.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Si l'école a désactivé le module notes, l'API répond 403 avec un
  /// message explicite (docs/PRODUCT_ARCHITECTURE.md §4 et §18) — propagé
  /// tel quel par ApiService, à afficher directement à l'utilisateur.
  Future<List<Note>> getNotes(int studentId) async {
    final data = await apiService.get('/children/$studentId/grades');
    return (data['data'] as List).map((e) => Note.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Announcement>> getAnnonces(int studentId) async {
    final data = await apiService.get('/children/$studentId/announcements');
    return (data['data'] as List).map((e) => Announcement.fromJson(e as Map<String, dynamic>)).toList();
  }
}
