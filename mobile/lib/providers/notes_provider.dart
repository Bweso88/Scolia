import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../models/periode.dart';
import '../models/matiere.dart';
import '../services/notes_service.dart';
import '../services/api_service.dart';

class NotesProvider extends ChangeNotifier {
  final _service = NotesService();

  List<NoteMatiere> _notesMatieres = [];
  List<Periode> _periodes = [];
  List<Matiere> _matieres = [];
  double? _moyenneGenerale;
  bool _charge = false;
  String? _erreur;

  List<NoteMatiere> get notesMatieres  => _notesMatieres;
  List<Periode>     get periodes       => _periodes;
  List<Matiere>     get matieres       => _matieres;
  double?           get moyenneGenerale => _moyenneGenerale;
  bool              get charge         => _charge;
  String?           get erreur         => _erreur;

  void mettreAJourToken(String? token) => apiService.setToken(token);

  Future<void> chargerPeriodes() async {
    if (_periodes.isNotEmpty) return;
    try {
      _periodes = await _service.getPeriodes();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> chargerMatieres({int? classeId}) async {
    try {
      _matieres = await _service.getMatieres(classeId: classeId);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> chargerBulletin(int eleveId, int periodeId) async {
    if (_charge) return;
    _charge = true; _erreur = null; _notesMatieres = [];
    notifyListeners();
    try {
      final data = await _service.getBulletin(eleveId, periodeId);
      _notesMatieres = (data['notes'] as List)
          .map((e) => NoteMatiere.fromJson(e as Map<String, dynamic>))
          .toList();
      final val = data['moyenne_generale'];
      _moyenneGenerale = val != null ? double.tryParse(val.toString()) : null;
    } on Exception catch (e) {
      _erreur = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _charge = false;
      notifyListeners();
    }
  }
}
