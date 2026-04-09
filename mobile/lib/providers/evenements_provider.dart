import 'package:flutter/foundation.dart';
import '../models/evenement.dart';
import '../services/evenements_service.dart';
import '../services/api_service.dart';

class EvenementsProvider extends ChangeNotifier {
  final _service = EvenementsService();

  List<Evenement> _evenements = [];
  bool _charge = false;
  String? _erreur;

  List<Evenement> get evenements => _evenements;
  bool get charge   => _charge;
  String? get erreur => _erreur;

  void mettreAJourToken(String? token) => apiService.setToken(token);

  Future<void> charger({bool futur = false}) async {
    if (_charge) return;
    _charge = true; _erreur = null;
    notifyListeners();
    try {
      _evenements = await _service.getEvenements(futur: futur);
    } on Exception catch (e) {
      _erreur = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _charge = false;
      notifyListeners();
    }
  }
}
