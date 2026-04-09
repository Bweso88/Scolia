import '../models/note.dart';
import '../models/periode.dart';
import '../models/matiere.dart';
import 'api_service.dart';

class NotesService {
  Future<Map<String, dynamic>> getBulletin(int eleveId, int periodeId) async {
    final data = await apiService.get('/notes/bulletin/$eleveId/$periodeId');
    return data;
  }

  Future<List<NoteMatiere>> getNotesMatieres(int eleveId, int periodeId) async {
    final data = await getBulletin(eleveId, periodeId);
    return (data['notes'] as List).map((e) => NoteMatiere.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<double?> getMoyenneGenerale(int eleveId, int periodeId) async {
    final data = await getBulletin(eleveId, periodeId);
    final val = data['moyenne_generale'];
    if (val == null) return null;
    return double.tryParse(val.toString());
  }

  Future<List<Periode>> getPeriodes() async {
    final data = await apiService.get('/periodes');
    return (data['periodes'] as List).map((e) => Periode.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Matiere>> getMatieres({int? classeId}) async {
    final data = await apiService.get('/matieres', params: classeId != null ? {'classe_id': classeId} : null);
    return (data['matieres'] as List).map((e) => Matiere.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saisirNote(Map<String, dynamic> corps) async {
    await apiService.post('/notes', body: corps);
  }
}
