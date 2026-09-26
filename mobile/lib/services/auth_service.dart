import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_context.dart';
import '../models/user.dart';
import 'api_service.dart';

typedef SessionAuth = ({String token, User user, List<AuthContext> contexts});

class AuthService {
  static const _keyToken = 'token';

  Future<SessionAuth> seConnecter(String email, String motDePasse) async {
    final data = await apiService.post('/auth/login', body: {
      'email': email,
      'password': motDePasse,
    });
    return _lireReponse(data);
  }

  /// Bascule vers un autre compte du même parent (autre école) sans
  /// ressaisir le mot de passe — nécessite le token de la session courante.
  Future<SessionAuth> basculerContexte(int userId) async {
    final data = await apiService.post('/auth/select-context', body: {'user_id': userId});
    return _lireReponse(data);
  }

  SessionAuth _lireReponse(Map<String, dynamic> data) {
    final token = data['token'] as String;
    final user = User.fromJson(data['user'] as Map<String, dynamic>);
    final contexts = (data['contexts'] as List? ?? [])
        .map((c) => AuthContext.fromJson(c as Map<String, dynamic>))
        .toList();
    return (token: token, user: user, contexts: contexts);
  }

  Future<void> deconnexion() async {
    try {
      await apiService.post('/auth/logout');
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    apiService.setToken(null);
  }

  Future<User> getProfil() async {
    final data = await apiService.get('/me');
    return User.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> sauvegarderToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  Future<String?> chargerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }
}
