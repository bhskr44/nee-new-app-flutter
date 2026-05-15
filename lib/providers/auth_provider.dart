import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  String? _error;
  bool _loading = false;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  bool get loading => _loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> checkAuthStatus() async {
    final token = await StorageService.getToken();
    if (token == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      final data = await apiService.getMe();
      _user = UserModel.fromJson(data);
      _status = AuthStatus.authenticated;
    } catch (_) {
      await StorageService.deleteToken();
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password, {String? fcmToken}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await apiService.login({
        'email': email,
        'password': password,
        if (fcmToken != null) 'fcm_token': fcmToken,
        'platform': 'android',
      });
      await StorageService.saveToken(data['token']);
      _user = UserModel.fromJson(data['user']);
      _status = AuthStatus.authenticated;
      _loading = false;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _error = _parseError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
    String role = 'buyer',
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await apiService.register({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        if (phone != null) 'phone': phone,
        'role': role,
      });
      await StorageService.saveToken(data['token']);
      _user = UserModel.fromJson(data['user']);
      _status = AuthStatus.authenticated;
      _loading = false;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _error = _parseError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _loading = true;
    notifyListeners();

    try {
      await apiService.logout();
    } catch (_) {}

    await StorageService.clearAll();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _loading = false;
    notifyListeners();
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await apiService.updateProfile(data);
      _user = UserModel.fromJson(result['user']);
      _loading = false;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _error = _parseError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Called after TrueCaller SDK returns a verified profile.
  Future<bool> loginWithTrueCaller({
    required String phone,
    required String name,
    required String accessToken,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await apiService.loginWithPhone({
        'phone': phone,
        'name': name,
        'access_token': accessToken,
        'provider': 'truecaller',
      });
      await StorageService.saveToken(data['token']);
      _user = UserModel.fromJson(data['user']);
      _status = AuthStatus.authenticated;
      _loading = false;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _error = _parseError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithPhoneNumber({
    required String phone,
    String? name,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await apiService.loginWithPhone({
        'phone': phone,
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        'provider': 'otp',
      });
      await StorageService.saveToken(data['token']);
      _user = UserModel.fromJson(data['user']);
      _status = AuthStatus.authenticated;
      _loading = false;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _error = _parseError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sync user state from a raw JSON map without a network call.
  void setUserFromData(Map<String, dynamic> userData) {
    _user = UserModel.fromJson(userData);
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _parseError(Exception e) {
    final msg = e.toString();
    if (msg.contains('422')) return 'Validation error. Check your inputs.';
    if (msg.contains('401')) return 'Invalid credentials.';
    if (msg.contains('SocketException') || msg.contains('Connection')) {
      return 'No internet connection.';
    }
    return 'Something went wrong. Try again.';
  }
}
