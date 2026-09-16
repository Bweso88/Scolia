import '../models/matiere.dart';
import 'api_service.dart';

/// Données de référence de l'école (matières...), utiles aux formulaires
/// de saisie (devoirs, notes, emploi du temps).
class ReferenceService {
  Future<List<Matiere>> getMatieres() async {
    final data = await apiService.get('/admin/subjects');
    return (data['data'] as List).map((e) => Matiere.fromJson(e as Map<String, dynamic>)).toList();
  }
}
