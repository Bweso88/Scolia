import 'package:flutter/foundation.dart';
import '../models/message_liaison.dart';
import '../services/liaison_service.dart';
import '../services/api_service.dart';

class LiaisonProvider extends ChangeNotifier {
  final _service = LiaisonService();

  List<MessageLiaison> _messages = [];
  bool _charge = false;
  String? _erreur;
  int _page = 1;
  bool _aPlus = true;

  List<MessageLiaison> get messages => _messages;
  bool get charge   => _charge;
  String? get erreur => _erreur;
  bool get aPlus    => _aPlus;

  void mettreAJourToken(String? token) => apiService.setToken(token);

  Future<void> charger({bool recharger = false}) async {
    if (_charge) return;
    if (recharger) { _messages = []; _page = 1; _aPlus = true; }
    if (!_aPlus) return;
    _charge = true; _erreur = null;
    notifyListeners();
    try {
      final nouveaux = await _service.getMessages(page: _page);
      _messages.addAll(nouveaux);
      _aPlus = nouveaux.isNotEmpty;
      if (_aPlus) _page++;
    } on Exception catch (e) {
      _erreur = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _charge = false;
      notifyListeners();
    }
  }

  Future<void> creerMessage(Map<String, dynamic> corps) async {
    await _service.creerMessage(corps);
    await charger(recharger: true);
  }

  Future<void> accuserReception(int id) async {
    await _service.accuserReception(id);
    final idx = _messages.indexWhere((m) => m.id == id);
    if (idx != -1) {
      notifyListeners();
    }
  }
}
