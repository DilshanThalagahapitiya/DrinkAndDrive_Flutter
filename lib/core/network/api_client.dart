// ============================================================
// API Client - Central HTTP client
// ============================================================
// Handles all HTTP requests to the DAD Backend REST API.
// Automatically attaches JWT token to authenticated requests.
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  ApiResponse({required this.success, required this.message, this.data});

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] as T?,
    );
  }
}

class ApiClient {
  static final ApiClient instance = ApiClient._();
  ApiClient._();

  String? _token;

  void setToken(String? token) => _token = token;
  String? get token => _token;

  Map<String, String> _headers({bool auth = true}) {
    final headers = {'Content-Type': 'application/json'};
    if (auth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // ---- GET ----
  Future<dynamic> get(String path, {bool auth = true}) async {
    final res = await http.get(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: _headers(auth: auth),
    );
    return _handleResponse(res);
  }

  // ---- POST ----
  Future<dynamic> post(String path, Map<String, dynamic> body, {bool auth = true}) async {
    final res = await http.post(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  // ---- PATCH ----
  Future<dynamic> patch(String path, Map<String, dynamic> body, {bool auth = true}) async {
    final res = await http.patch(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  // ---- Response handler ----
  dynamic _handleResponse(http.Response res) {
    final decoded = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded;
    } else {
      throw ApiException(decoded['message'] ?? 'Request failed');
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}