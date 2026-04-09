import 'package:flutter/foundation.dart';
import '../models/frais_scolarite.dart';
import '../services/frais_service.dart';
import '../services/api_service.dart';

class FraisProvider extends ChangeNotifier {
  final _service = FraisService();

  List<FraisScolarite> _frais = [];
  ResumeFrais? _resume;
  bool _charge = false;
  String? _erreur;

  List<FraisScolarite> get frais  => _frais;
  ResumeFrais?         get resume => _resume;
  bool                 get charge => _charge;
  String?              get erreur => _erreur;

  void mettreAJourToken(String? token) => apiService.setToken(token);

  Future<void> chargerFraisEleve(int eleveId) async {
    if (_charge) return;
    _charge = true; _erreur = null;
    notifyListeners();
    try {
      _frais  = await _service.getFraisEleve(eleveId);
      _resume = await _service.getResume(eleveId);
    } on Exception catch (e) {
      _erreur = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _charge = false;
      notifyListeners();
    }
  }
}
