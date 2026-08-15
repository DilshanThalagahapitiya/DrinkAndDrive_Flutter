// ============================================================
// Auth Repository
// ============================================================
// Handles authentication API calls: login, signup, and Google sign-in.
// ============================================================

import '../../../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _api = ApiClient.instance;

  // ---- LOGIN ----
  Future<AuthResult> login(String email, String password) async {
    final response = await _api.post('/api/auth/login', {
      'email': email,
      'password': password,
    }, auth: false);

    final data = response['data'] as Map<String, dynamic>;
    final result = AuthResult.fromJson(data);
    _api.setToken(result.token);
    return result;
  }

  // ---- SIGNUP ----
  Future<AuthResult> signup(Map<String, dynamic> userData) async {
    final response = await _api.post('/api/auth/signup', userData, auth: false);
    final data = response['data'] as Map<String, dynamic>;
    final result = AuthResult.fromJson(data);
    if (result.token.isNotEmpty) {
      _api.setToken(result.token);
    }
    return result;
  }

  // ---- GOOGLE SIGN-IN ----
  Future<AuthResult> googleSignIn(String idToken, {String role = 'CUSTOMER'}) async {
    final response = await _api.post('/api/auth/google', {
      'idToken': idToken,
      'role': role,
    }, auth: false);
    final data = response['data'] as Map<String, dynamic>;
    final result = AuthResult.fromJson(data);
    if (result.token.isNotEmpty) {
      _api.setToken(result.token);
    }
    return result;
  }

  // ---- LOGOUT ----
  Future<void> logout() async {
    try {
      await _api.post('/api/auth/logout', {});
    } catch (_) {
      // Ignore logout errors - just clear token
    }
    _api.setToken(null);
  }
}