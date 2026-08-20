import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  static Future<UserModel> login(String email, String password) async {
    final data = await ApiService.post(
      ApiConfig.login,
      {'email': email, 'password': password},
      auth: false,
    );
    final user = UserModel.fromJson(data);
    await ApiService.saveToken(user.token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(data));
    return user;
  }

  static Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    String? ngoName,
  }) async {
    final body = {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      if (phone != null) 'phone': phone,
      if (ngoName != null) 'ngoName': ngoName,
    };
    final data = await ApiService.post(ApiConfig.register, body, auth: false);
    final user = UserModel.fromJson(data);
    await ApiService.saveToken(user.token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(data));
    return user;
  }

  static Future<UserModel?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('user');
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  static Future<void> logout() async {
    await ApiService.clearToken();
  }

  static Future<UserModel> loginWithGoogle(String idToken, {String? role}) async {
    final data = await ApiService.post(
      '${ApiConfig.baseUrl}/auth/google',
      {
        'idToken': idToken,
        if (role != null) 'role': role,
      },
      auth: false,
    );
    final user = UserModel.fromJson(data);
    await ApiService.saveToken(user.token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(data));
    return user;
  }
}
