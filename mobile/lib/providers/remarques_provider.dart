import 'package:flutter/foundation.dart';
import '../models/remarque.dart';
import '../services/remarques_service.dart';
import '../services/api_service.dart';

class RemarquesProvider extends ChangeNotifier {
  final _service = RemarquesService();

  List<Remarque> _remarques = [];
  bool _charge = false;
  String? _erreur;
  int _page = 1;
  bool _aPlus = true;

  List<Remarque> get remarques => _remarques;
  bool get charge   => _charge;
  String? get erreur => _erreur;
  bool get aPlus    => _aPlus;

  void mettreAJourToken(String? token) => apiService.setToken(token);

  Future<void> charger({bool recharger = false}) async {
    if (_charge) return;
    if (recharger) { _remarques = []; _page = 1; _aPlus = true; }
    if (!_aPlus) return;
    _charge = true; _erreur = null;
    notifyListeners();
    try {
      final nouvelles = await _service.getRemarques(page: _page);
      _remarques.addAll(nouvelles);
      _aPlus = nouvelles.isNotEmpty;
      if (_aPlus) _page++;
    } on Exception catch (e) {
      _erreur = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _charge = false;
      notifyListeners();
    }
  }

  Future<void> creerRemarque(Map<String, dynamic> corps) async {
    await _service.creerRemarque(corps);
    await charger(recharger: true);
  }
}
