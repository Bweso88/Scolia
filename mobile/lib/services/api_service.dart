import 'package:dio/dio.dart';
import '../config/app_config.dart';

class ApiService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl:        AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: AppConfig.timeoutSecondes),
    receiveTimeout: const Duration(seconds: AppConfig.timeoutSecondes),
    headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
  ))..interceptors.add(LogInterceptor(responseBody: false));

  String? _token;

  void setToken(String? token) {
    _token = token;
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? params}) async {
    try {
      final r = await _dio.get(path, queryParameters: params);
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _traiterErreur(e);
    }
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) async {
    try {
      final r = await _dio.post(path, data: body);
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _traiterErreur(e);
    }
  }

  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) async {
    try {
      final r = await _dio.put(path, data: body);
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _traiterErreur(e);
    }
  }

  Future<void> delete(String path) async {
    try {
      await _dio.delete(path);
    } on DioException catch (e) {
      throw _traiterErreur(e);
    }
  }

  Exception _traiterErreur(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return Exception('Pas de connexion réseau. Vérifiez votre connexion.');
    }
    final data = e.response?.data;
    if (data is Map && data.containsKey('erreur')) {
      return Exception(data['erreur'] as String);
    }
    return Exception('Erreur réseau (${e.response?.statusCode ?? 'inconnu'})');
  }
}

final apiService = ApiService();
