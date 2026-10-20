import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/auth_context.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();

  User? _user;
  String? _token;
  List<AuthContext> _contexts = [];
  bool _charge = false;
  String? _erreur;
  final Completer<void> _restaurationTerminee = Completer<void>();

  User?   get user       => _user;
  String? get token      => _token;
  bool    get estConnecte => _token != null && _user != null;
  bool    get charge     => _charge;
  String? get erreur     => _erreur;

  /// Se termine une fois la tentative de restauration de session (au
  /// démarrage) aboutie, succès ou échec — l'écran de démarrage l'attend
  /// avant de décider où naviguer, pour ne jamais afficher la connexion
  /// puis basculer tout seul vers l'accueil une fois la session restaurée.
  Future<void> get sessionRestauree => _restaurationTerminee.future;

  /// Autres écoles accessibles avec la même identité parent
  /// (docs/PRODUCT_ARCHITECTURE.md §9) — vide si le compte n'est lié à
  /// aucune autre école, ou contient toujours le contexte actuel sinon.
  List<AuthContext> get contexts => _contexts;
  bool get aPlusieursEcoles => _contexts.length > 1;

  AuthProvider() {
    _restaurerSession();
  }

  Future<void> _restaurerSession() async {
    try {
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
    } finally {
      _restaurationTerminee.complete();
    }
  }

  Future<void> seConnecter(String email, String motDePasse) async {
    _erreur = null;
    _charge = true;
    notifyListeners();
    try {
      final result = await _authService.seConnecter(email, motDePasse);
      await _appliquerSession(result);
    } on Exception catch (e) {
      _erreur = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _charge = false;
      notifyListeners();
    }
  }

  /// Change d'école sans redemander le mot de passe.
  Future<void> basculerContexte(int userId) async {
    _erreur = null;
    _charge = true;
    notifyListeners();
    try {
      final result = await _authService.basculerContexte(userId);
      await _appliquerSession(result);
    } on Exception catch (e) {
      _erreur = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _charge = false;
      notifyListeners();
    }
  }

  Future<void> _appliquerSession(SessionAuth result) async {
    _token = result.token;
    _user = result.user;
    _contexts = result.contexts;
    apiService.setToken(_token);
    await _authService.sauvegarderToken(_token!);
    await _enregistrerTokenFCM();
  }

  Future<void> deconnexion() async {
    try {
      await _authService.deconnexion();
    } catch (_) {}
    _token = null;
    _user = null;
    _contexts = [];
    notifyListeners();
  }

  Future<void> _enregistrerTokenFCM() async {
    final fcmToken = await NotificationService.getToken();
    if (fcmToken != null) {
      await NotificationService.enregistrerToken(fcmToken);
    }
  }

  /// Renvoie au backend un token FCM renouvelé par le système (voir
  /// NotificationService.onTokenRefreshed, branché depuis app.dart).
  /// Sans session active, il n'y a personne à qui l'associer.
  Future<void> renvoyerTokenFCM(String token) async {
    if (!estConnecte) return;
    try {
      await NotificationService.enregistrerToken(token);
    } catch (_) {}
  }
}
