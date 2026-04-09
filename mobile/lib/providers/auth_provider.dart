import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();

  User? _user;
  String? _token;
  bool _charge = false;
  String? _erreur;

  User?   get user       => _user;
  String? get token      => _token;
  bool    get estConnecte => _token != null && _user != null;
  bool    get charge     => _charge;
  String? get erreur     => _erreur;

  AuthProvider() {
    _restaurerSession();
  }

  Future<void> _restaurerSession() async {
    final token = await _authService.chargerToken();
    if (token == null) return;
    _token = token;
    apiService.setToken(token);
    try {
      _user = await _authService.getProfil();
      await _enregistrerTokenFCM();
    } catch (_) {
      _token = null;
      apiService.setToken(null);
    }
    notifyListeners();
  }

  Future<void> demanderOtp(String telephone) async {
    _erreur = null;
    _charge = true;
    notifyListeners();
    try {
      await _authService.demanderOtp(telephone);
    } on Exception catch (e) {
      _erreur = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _charge = false;
      notifyListeners();
    }
  }

  Future<void> verifierOtp(String telephone, String code) async {
    _erreur = null;
    _charge = true;
    notifyListeners();
    try {
      final result = await _authService.verifierOtp(telephone, code);
      _token = result.token;
      _user  = result.user;
      apiService.setToken(_token);
      await _authService.sauvegarderToken(_token!, _user!);
      await _enregistrerTokenFCM();
    } on Exception catch (e) {
      _erreur = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _charge = false;
      notifyListeners();
    }
  }

  Future<void> deconnexion() async {
    try { await _authService.deconnexion(); } catch (_) {}
    _token = null;
    _user  = null;
    notifyListeners();
  }

  Future<void> _enregistrerTokenFCM() async {
    final fcmToken = await NotificationService.getToken();
    if (fcmToken != null) {
      await NotificationService.enregistrerToken(fcmToken);
    }
  }
}
