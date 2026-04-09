import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  static const _keyToken = 'token';
  static const _keyRole  = 'role';
  static const _keyUserId = 'user_id';

  Future<void> demanderOtp(String telephone) async {
    await apiService.post('/auth/demander-otp', body: {
      'telephone':  telephone,
      'ecole_slug': AppConfig.ecoleSlug,
    });
  }

  Future<({String token, User user})> verifierOtp(String telephone, String code) async {
    final data = await apiService.post('/auth/verifier-otp', body: {
      'telephone':  telephone,
      'code':       code,
      'ecole_slug': AppConfig.ecoleSlug,
    });
    final token = data['token'] as String;
    final user  = User.fromJson(data['utilisateur'] as Map<String, dynamic>);
    return (token: token, user: user);
  }

  Future<void> deconnexion() async {
    await apiService.post('/auth/deconnexion');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyUserId);
    apiService.setToken(null);
  }

  Future<User?> getProfil() async {
    final data = await apiService.get('/auth/profil');
    return User.fromJson(data['profil'] as Map<String, dynamic>);
  }

  Future<void> sauvegarderToken(String token, User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyRole, user.role);
    await prefs.setInt(_keyUserId, user.id);
  }

  Future<String?> chargerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }
}
