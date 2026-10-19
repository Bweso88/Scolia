import '../models/academic_event.dart';
import 'api_service.dart';

/// Événements du calendrier scolaire (/api/v1/admin/academic-events) — ouvert
/// en lecture à tout utilisateur du tenant, création réservée à la direction.
class AcademicEventService {
  Future<List<AcademicEvent>> getEvenements() async {
    final data = await apiService.get('/admin/academic-events');
    return (data['data'] as List).map((e) => AcademicEvent.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> creerEvenement(Map<String, dynamic> corps) async {
    await apiService.post('/admin/academic-events', body: corps);
  }

  Future<void> supprimerEvenement(int id) async {
    await apiService.delete('/admin/academic-events/$id');
  }
}
