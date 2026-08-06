// ============================================================
// Auth Provider - State management for authentication
// Supports "Keep me logged in" via a rememberMe flag.
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  bool _keepLoggedIn = true; // Keep me logged in default ON

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  String get role => _user?.role ?? '';
  bool get keepLoggedIn => _keepLoggedIn;

  // ---- LOGIN ----
  Future<bool> login(String email, String password, {bool keepLoggedIn = true}) async {
    _setLoading(true);
    try {
      final result = await _repo.login(email, password);
      _user = result.user;
      _keepLoggedIn = keepLoggedIn;
      await _saveToken(result.token);
      await _saveUser(result.user);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ---- SIGNUP ----
  Future<bool> signup(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final result = await _repo.signup(data);
      if (result.token.isNotEmpty) {
        _user = result.user;
        await _saveToken(result.token);
        await _saveUser(result.user);
      }
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ---- RESTORE SESSION (called on app start) ----
  Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('dad_token');
    if (token == null) return false;

    final userStr = prefs.getString('dad_user');
    if (userStr == null || userStr.isEmpty) return false;

    // Stored format: "id|email|fullName|role|status|phone"
    final parts = userStr.split('|');
    if (parts.length >= 4) {
      // CRITICAL: restore the token in the ApiClient so API calls are authenticated
      ApiClient.instance.setToken(token);
      _user = UserModel(
        id: parts[0],
        email: parts[1],
        fullName: parts[2],
        role: parts[3],
        status: parts.length > 4 ? parts[4] : 'APPROVED',
        phone: parts.length > 5 ? parts[5] : '',
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  // ---- CLEAR SESSION when "Keep me logged in" is OFF ----
  Future<void> clearSessionOnExit() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('dad_token');
    await prefs.remove('dad_user');
    _user = null;
    notifyListeners();
  }

  // ---- LOGOUT ----
  Future<void> logout() async {
    await _repo.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('dad_token');
    await prefs.remove('dad_user');
    _user = null;
    notifyListeners();
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dad_token', token);
  }

  Future<void> _saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'dad_user',
        '${user.id}|${user.email}|${user.fullName}|${user.role}|${user.status}|${user.phone}');
  }

  void _setLoading(bool val) {
    _isLoading = val;
    _error = null;
    notifyListeners();
  }
}