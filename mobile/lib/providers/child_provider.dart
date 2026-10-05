import 'package:flutter/foundation.dart';
import '../models/student.dart';
import '../services/children_service.dart';
import '../services/api_service.dart';

/// Enfant actuellement consulté par un parent (docs/PRODUCT_ARCHITECTURE.md
/// §12) : le sélecteur reste visible depuis le tableau de bord et
/// s'applique à tous les modules (devoirs, comportement, absences, notes).
class ChildProvider extends ChangeNotifier {
  final _service = ChildrenService();

  List<Student> _enfants = [];
  Student? _selectionne;
  bool _charge = false;
  String? _erreur;

  List<Student> get enfants     => _enfants;
  Student?      get selectionne => _selectionne;
  bool          get charge      => _charge;
  String?       get erreur      => _erreur;

  void mettreAJourToken(String? token) => apiService.setToken(token);

  Future<void> charger() async {
    _charge = true;
    _erreur = null;
    notifyListeners();
    try {
      _enfants = await _service.getEnfants();
      if (_selectionne == null || !_enfants.any((e) => e.id == _selectionne!.id)) {
        _selectionne = _enfants.isNotEmpty ? _enfants.first : null;
      }
    } on Exception catch (e) {
      _erreur = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _charge = false;
      notifyListeners();
    }
  }

  void selectionner(Student enfant) {
    if (_selectionne?.id == enfant.id) return;
    _selectionne = enfant;
    notifyListeners();
  }
}
