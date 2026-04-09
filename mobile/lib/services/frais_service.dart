import '../models/frais_scolarite.dart';
import 'api_service.dart';

class FraisService {
  Future<List<FraisScolarite>> getFraisEleve(int eleveId) async {
    final data = await apiService.get('/frais/eleve/$eleveId');
    return (data['frais'] as List).map((e) => FraisScolarite.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ResumeFrais> getResume(int eleveId, {String? anneeScolaire}) async {
    final data = await apiService.get('/frais/resume/$eleveId',
        params: anneeScolaire != null ? {'annee_scolaire': anneeScolaire} : null);
    return ResumeFrais.fromJson(data['resume'] as Map<String, dynamic>);
  }
}
