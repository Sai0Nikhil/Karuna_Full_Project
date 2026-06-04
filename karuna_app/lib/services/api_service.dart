import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  // ─── Token helpers ────────────────────────────────────────────────────
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  // ─── Auth headers ────────────────────────────────────────────────────
  static Future<Map<String, String>> authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── HTTP helpers ────────────────────────────────────────────────────
  static Future<dynamic> get(String url) async {
    final headers = await authHeaders();
    final res = await http.get(Uri.parse(url), headers: headers)
        .timeout(ApiConfig.timeout);
    return _handle(res);
  }

  static Future<dynamic> post(String url, Map<String, dynamic> body,
      {bool auth = true}) async {
    final headers = auth
        ? await authHeaders()
        : {'Content-Type': 'application/json'};
    final res = await http
        .post(Uri.parse(url), headers: headers, body: jsonEncode(body))
        .timeout(ApiConfig.timeout);
    return _handle(res);
  }

  static Future<dynamic> put(String url, Map<String, dynamic> body) async {
    final headers = await authHeaders();
    final res = await http
        .put(Uri.parse(url), headers: headers, body: jsonEncode(body))
        .timeout(ApiConfig.timeout);
    return _handle(res);
  }

  // ─── Response handler ─────────────────────────────────────────────────
  static dynamic _handle(http.Response res) {
    final body = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    final msg = (body is Map && body['message'] != null)
        ? body['message']
        : 'Request failed (${res.statusCode})';
    throw ApiException(msg, res.statusCode);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
