import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:exam_grading/config/api_config.dart';

/// Service จัดการ Authentication ผ่าน REST API แทน Firebase
class AuthService {
  static const _keyEmail = 'user_email';
  static const _keyDisplayName = 'user_displayName';
  static const _keyPhotoURL = 'user_photoURL';
  static const _keyRole = 'user_role';

  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  AuthService._();

  // ── Cached user (in-memory) ──────────────────────────────────────────────
  Map<String, dynamic>? _currentUser;

  Map<String, dynamic>? get currentUser => _currentUser;
  String? get currentEmail => _currentUser?['email'] as String?;
  bool get isLoggedIn => _currentUser != null;

  // ── Initialise: อ่าน session จาก SharedPreferences ─────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_keyEmail);
    if (email != null && email.isNotEmpty) {
      _currentUser = {
        'email': email,
        'displayName': prefs.getString(_keyDisplayName) ?? '',
        'photoURL': prefs.getString(_keyPhotoURL) ?? '',
        'role': prefs.getString(_keyRole) ?? 'user',
      };
    }
  }

  // ── Save session ────────────────────────────────────────────────────────
  Future<void> _saveSession(Map<String, dynamic> user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmail, user['email'] ?? '');
    await prefs.setString(_keyDisplayName, user['displayName'] ?? '');
    await prefs.setString(_keyPhotoURL, user['photoURL'] ?? '');
    await prefs.setString(_keyRole, user['role'] ?? 'user');
  }

  // ── Clear session (Logout) ───────────────────────────────────────────────
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyDisplayName);
    await prefs.remove(_keyPhotoURL);
    await prefs.remove(_keyRole);
  }

  // ── Email/Password Login ────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    final resp = await http
        .post(
          ApiConfig.endpoint('/api/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 20));

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      await _saveSession(data);
      return data;
    }

    final detail = _extractDetail(resp);
    throw AuthException(detail);
  }

  // ── Register ────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String displayName,
  ) async {
    final resp = await http
        .post(
          ApiConfig.endpoint('/api/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'password': password,
            'displayName': displayName,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }

    final detail = _extractDetail(resp);
    throw AuthException(detail);
  }

  // ── Google Sign-In via Access Token ────────────────────────────────────
  Future<Map<String, dynamic>> loginWithGoogle(String accessToken) async {
    final resp = await http
        .post(
          ApiConfig.endpoint('/api/auth/google'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'access_token': accessToken}),
        )
        .timeout(const Duration(seconds: 30));

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      await _saveSession(data);
      return data;
    }

    final detail = _extractDetail(resp);
    throw AuthException(detail);
  }

  // ── Update local profile cache ──────────────────────────────────────────
  Future<void> updateLocalProfile({
    String? displayName,
    String? photoURL,
  }) async {
    if (_currentUser == null) return;
    if (displayName != null) _currentUser!['displayName'] = displayName;
    if (photoURL != null) _currentUser!['photoURL'] = photoURL;
    final prefs = await SharedPreferences.getInstance();
    if (displayName != null) {
      await prefs.setString(_keyDisplayName, displayName);
    }
    if (photoURL != null) await prefs.setString(_keyPhotoURL, photoURL);
  }

  // ── Helper ──────────────────────────────────────────────────────────────
  String _extractDetail(http.Response resp) {
    try {
      final body = jsonDecode(resp.body);
      return body['detail']?.toString() ??
          'เกิดข้อผิดพลาด (${resp.statusCode})';
    } catch (_) {
      return 'เกิดข้อผิดพลาด (${resp.statusCode})';
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}
