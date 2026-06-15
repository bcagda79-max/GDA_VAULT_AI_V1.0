import 'package:dio/dio.dart';
import 'package:gda_vault_ai/core/services/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final AuthService instance = AuthService._internal();
  final ApiClient _apiClient = ApiClient.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  AuthService._internal();

  static const String _tokenKey = 'jwt_token';

  Future<bool> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data.containsKey('access_token')) {
        final token = response.data['access_token'];
        await _secureStorage.write(key: _tokenKey, value: token);
        return true;
      }
      return false;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Login Error: \${e.response?.data}');
      }
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    try {
      final response = await _apiClient.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
        },
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Register Error: \${e.response?.data}');
      }
      return false;
    }
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: _tokenKey);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<Map<String, dynamic>?> getCurrentProfile() async {
    try {
      final response = await _apiClient.get('/profiles');
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Get Profile Error: $e');
      }
      return null;
    }
  }
}
