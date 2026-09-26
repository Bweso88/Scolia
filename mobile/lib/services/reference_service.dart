import '../models/matiere.dart';
import 'api_service.dart';

/// Données de référence de l'école (matières...), utiles aux formulaires
/// de saisie (devoirs, notes, emploi du temps).
class ReferenceService {
  Future<List<Matiere>> getMatieres() async {
    final data = await apiService.get('/admin/subjects');
    return (data['data'] as List).map((e) => Matiere.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> creerMatiere(String nom) async {
    await apiService.post('/admin/subjects', body: {'name': nom});
  }

  Future<void> modifierMatiere(int id, String nom) async {
    await apiService.patch('/admin/subjects/$id', body: {'name': nom});
  }

  Future<void> supprimerMatiere(int id) async {
    await apiService.delete('/admin/subjects/$id');
  }
}
