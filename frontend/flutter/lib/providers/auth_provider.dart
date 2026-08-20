import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _loading = false;
  String? _error;

  UserModel? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isCitizen => _user?.isCitizen ?? false;
  bool get isNgo => _user?.isNgo ?? false;
  bool get isVolunteer => _user?.role == 'volunteer' || _user?.role == 'VOLUNTEER';
  bool get isVet => _user?.role == 'vet' || _user?.role == 'VET';

  /// Restore session from SharedPreferences on app start
  Future<void> init() async {
    _user = await AuthService.getStoredUser();
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await AuthService.login(email, password);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithGoogle(String idToken, {String? role}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await AuthService.loginWithGoogle(idToken, role: role);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    String? ngoName,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await AuthService.register(
        name: name,
        email: email,
        password: password,
        role: role,
        phone: phone,
        ngoName: ngoName,
      );
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
