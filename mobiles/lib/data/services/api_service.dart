import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:exam_grading/config/api_config.dart';

/// Generic REST API service แทน Firebase Firestore
/// URL pattern: GET/POST/PUT/PATCH/DELETE /api/db/{userEmail}/{collection}/{docId?}
class ApiService {
  static ApiService? _instance;
  static ApiService get instance => _instance ??= ApiService._();
  ApiService._();

  // ── Build URL ──────────────────────────────────────────────────────────
  Uri _url(String userEmail, String collection, [String? docId]) {
    final encoded = Uri.encodeComponent(userEmail);
    final path = docId != null
        ? '/api/db/users/$encoded/$collection/$docId'
        : '/api/db/users/$encoded/$collection';
    return ApiConfig.endpoint(path);
  }

  Uri _urlNested(
    String userEmail,
    String parentCollection,
    String parentId,
    String childCollection, [
    String? childId,
  ]) {
    final encoded = Uri.encodeComponent(userEmail);
    final path = childId != null
        ? '/api/db/users/$encoded/$parentCollection/$parentId/$childCollection/$childId'
        : '/api/db/users/$encoded/$parentCollection/$parentId/$childCollection';
    return ApiConfig.endpoint(path);
  }

  // ── Headers ─────────────────────────────────────────────────────────────
  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  // ── GET collection ───────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getCollection(
    String userEmail,
    String collection, {
    Map<String, String>? queryParams,
  }) async {
    var uri = _url(userEmail, collection);
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }
    final resp = await http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 20));
    _assertOk(resp);
    final body = jsonDecode(resp.body);
    if (body is List) {
      return body.cast<Map<String, dynamic>>();
    }
    return [];
  }

  // ── GET nested collection ────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getNestedCollection(
    String userEmail,
    String parentCollection,
    String parentId,
    String childCollection,
  ) async {
    final uri = _urlNested(
      userEmail,
      parentCollection,
      parentId,
      childCollection,
    );
    final resp = await http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 20));
    _assertOk(resp);
    final body = jsonDecode(resp.body);
    if (body is List) {
      return body.cast<Map<String, dynamic>>();
    }
    return [];
  }

  // ── GET single doc ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getDoc(
    String userEmail,
    String collection,
    String docId,
  ) async {
    final resp = await http
        .get(_url(userEmail, collection, docId), headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (resp.statusCode == 404) return null;
    _assertOk(resp);
    return jsonDecode(resp.body) as Map<String, dynamic>?;
  }

  // ── POST (add doc, auto-ID) ──────────────────────────────────────────────
  Future<String?> addDoc(
    String userEmail,
    String collection,
    Map<String, dynamic> data,
  ) async {
    final resp = await http
        .post(
          _url(userEmail, collection),
          headers: _headers,
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 20));
    _assertOk(resp);
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    return body['id']?.toString();
  }

  // ── PUT (set doc with specific ID) ───────────────────────────────────────
  Future<void> setDoc(
    String userEmail,
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    final resp = await http
        .put(
          _url(userEmail, collection, docId),
          headers: _headers,
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 20));
    _assertOk(resp);
  }

  // ── PUT nested doc ────────────────────────────────────────────────────────
  Future<void> setNestedDoc(
    String userEmail,
    String parentCollection,
    String parentId,
    String childCollection,
    String childId,
    Map<String, dynamic> data,
  ) async {
    final uri = _urlNested(
      userEmail,
      parentCollection,
      parentId,
      childCollection,
      childId,
    );
    final resp = await http
        .put(uri, headers: _headers, body: jsonEncode(data))
        .timeout(const Duration(seconds: 20));
    _assertOk(resp);
  }

  // ── PATCH (update doc) ────────────────────────────────────────────────────
  Future<void> updateDoc(
    String userEmail,
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    final resp = await http
        .patch(
          _url(userEmail, collection, docId),
          headers: _headers,
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 20));
    _assertOk(resp);
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  Future<void> deleteDoc(
    String userEmail,
    String collection,
    String docId,
  ) async {
    final resp = await http
        .delete(_url(userEmail, collection, docId), headers: _headers)
        .timeout(const Duration(seconds: 20));
    _assertOk(resp);
  }

  // ── DELETE nested doc ─────────────────────────────────────────────────────
  Future<void> deleteNestedDoc(
    String userEmail,
    String parentCollection,
    String parentId,
    String childCollection,
    String childId,
  ) async {
    final uri = _urlNested(
      userEmail,
      parentCollection,
      parentId,
      childCollection,
      childId,
    );
    final resp = await http
        .delete(uri, headers: _headers)
        .timeout(const Duration(seconds: 20));
    _assertOk(resp);
  }

  // ── Academic Settings ─────────────────────────────────────────────────────
  /// ดึงค่า academic_year และ academic_term จาก /api/settings/academic_year
  Future<Map<String, dynamic>> getAcademicSettings() async {
    final uri = ApiConfig.endpoint('/api/settings/academic_year');
    final resp = await http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 20));
    _assertOk(resp);
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  // ── Helper ──────────────────────────────────────────────────────────────
  void _assertOk(http.Response resp) {
    if (resp.statusCode >= 200 && resp.statusCode < 300) return;
    String detail = 'เกิดข้อผิดพลาด (${resp.statusCode})';
    try {
      final body = jsonDecode(resp.body);
      detail = body['detail']?.toString() ?? detail;
    } catch (_) {}
    throw ApiException(detail, resp.statusCode);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);
  @override
  String toString() => message;
}
