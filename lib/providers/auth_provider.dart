import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/constants.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  String? _error;
  bool _loading = false;
  bool _isNewUser = false;

  AuthProvider() {
    apiService.onAccountFrozen = markFrozen;
    apiService.onPhoneNotVerified = requestPhoneVerification;
  }

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  bool get loading => _loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// True once an ACCOUNT_FROZEN response has been seen for the current
  /// session, or the cached profile is already past its approval/guest
  /// window — the router redirects to the blocking screen either way.
  bool _frozen = false;
  bool get isFrozen => _frozen || (_user?.profile?.isFrozen ?? false);
  String? _frozenMessage;
  String? get frozenMessage => _frozenMessage;

  /// Called by ApiService's response interceptor whenever the backend returns
  /// {"code": "ACCOUNT_FROZEN"} — flips the router into the blocking screen
  /// immediately instead of waiting for the next full profile refresh.
  void markFrozen(String message) {
    _frozen = true;
    _frozenMessage = message;
    notifyListeners();
  }


  /// A Google sign-in without an OTP-verified phone. The router shows the
  /// verify-phone screen while this is true and the prompt isn't dismissed.
  bool get needsPhoneVerification => _user?.needsPhoneVerification ?? false;

  /// The verify-phone screen can be closed (back / "Later") — that only lasts
  /// for this app session, and any feature the backend then refuses with
  /// PHONE_NOT_VERIFIED brings it straight back.
  bool _phoneVerifyDismissed = false;
  DateTime? _phoneVerifyDismissedAt;
  bool get shouldPromptPhoneVerification =>
      needsPhoneVerification && !_phoneVerifyDismissed;

  void dismissPhoneVerification() {
    _phoneVerifyDismissed = true;
    _phoneVerifyDismissedAt = DateTime.now();
    notifyListeners();
  }

  /// Called by ApiService's interceptor on PHONE_NOT_VERIFIED. Ignored for a
  /// few seconds right after a dismissal: the home screen's own background
  /// loads would otherwise bounce the user straight back to the prompt they
  /// just closed — the next thing they actually tap reopens it.
  void requestPhoneVerification() {
    if (!_phoneVerifyDismissed) return;
    final at = _phoneVerifyDismissedAt;
    if (at != null && DateTime.now().difference(at) < const Duration(seconds: 3)) {
      return;
    }
    _phoneVerifyDismissed = false;
    notifyListeners();
  }

  /// True when the last phone login auto-created the account (first time user).
  bool get isNewUser => _isNewUser;

  /// Registers (or re-registers) this device's FCM token against the current
  /// user. Called after every successful auth transition — covers both "the
  /// token was never registered because the app opened before login" (boot →
  /// checkAuthStatus) and "make sure it's current at login" cases. Fire-and-
  /// forget: never blocks the auth flow, and any failure is silent since it
  /// isn't user-visible and will simply retry on the next app open.
  Future<void> _syncFcmToken() async {
    try {
      final token = await notificationService.getToken();
      if (token == null) return;
      final platform = Platform.isIOS ? 'ios' : 'android';
      await apiService.registerFcmToken(token, platform);
    } catch (_) {}
  }

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
      unawaited(_syncFcmToken());
    } catch (_) {
      await StorageService.deleteToken();
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Refresh server-controlled user data such as feature flags without
  /// changing the current session when the network is temporarily unavailable.
  Future<void> refreshUser() async {
    if (_status != AuthStatus.authenticated) return;

    try {
      final data = await apiService.getMe();
      _user = UserModel.fromJson(data);
      notifyListeners();
    } catch (_) {
      // Keep the current in-memory user. The next app resume will retry.
    }
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await apiService.login({
        'email': email,
        'password': password,
        'platform': 'android',
      });
      await StorageService.saveToken(data['token']);
      _user = UserModel.fromJson(data['user']);
      _status = AuthStatus.authenticated;
      _loading = false;
      notifyListeners();
      unawaited(_syncFcmToken());
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
    String? referralCode,
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
        if (referralCode != null) 'referral_code': referralCode,
      });
      await StorageService.saveToken(data['token']);
      _user = UserModel.fromJson(data['user']);
      _status = AuthStatus.authenticated;
      _loading = false;
      notifyListeners();
      unawaited(_syncFcmToken());
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

    if (_googleInitialized) {
      // So the next "Continue with Google" shows the account chooser again.
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }

    await StorageService.clearAll();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _frozen = false;
    _frozenMessage = null;
    _phoneVerifyDismissed = false;
    _phoneVerifyDismissedAt = null;
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

  Future<bool> loginWithPhoneNumber({
    required String phone,
    String? otp,
    String? name,
    String? role,
    String? email,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await apiService.loginWithPhone({
        'phone': phone,
        if (otp != null) 'otp': otp,
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        if (role != null) 'role': role,
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        'provider': 'otp',
      });
      await StorageService.saveToken(data['token']);
      _user = UserModel.fromJson(data['user']);
      _isNewUser = data['is_new_user'] == true;
      _status = AuthStatus.authenticated;
      _loading = false;
      notifyListeners();
      unawaited(_syncFcmToken());
      return true;
    } on Exception catch (e) {
      _error = _parseError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithTrueCaller({
    required String authorizationCode,
    required String state,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await apiService.loginWithPhone({
        'provider': 'truecaller',
        'authorization_code': authorizationCode,
        'state': state,
      });
      await StorageService.saveToken(data['token']);
      _user = UserModel.fromJson(data['user']);
      _isNewUser = data['is_new_user'] == true;
      _status = AuthStatus.authenticated;
      _loading = false;
      notifyListeners();
      unawaited(_syncFcmToken());
      return true;
    } on Exception catch (e) {
      _error = _parseError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  static bool _googleInitialized = false;

  static bool get googleSignInAvailable =>
      AppConstants.googleServerClientId.isNotEmpty && Platform.isAndroid;

  /// "Continue with Google". Returns false with [error] set on failure, and
  /// false with no error when the user just closed Google's account picker.
  Future<bool> loginWithGoogle() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      if (!_googleInitialized) {
        await GoogleSignIn.instance.initialize(
          serverClientId: AppConstants.googleServerClientId,
        );
        _googleInitialized = true;
      }
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw Exception('Google did not return an ID token');
      }

      // The FCM token is registered by _syncFcmToken() below, as for every login.
      final data = await apiService.loginWithGoogle({'id_token': idToken});
      await StorageService.saveToken(data['token']);
      _user = UserModel.fromJson(data['user']);
      _isNewUser = data['is_new_user'] == true;
      _phoneVerifyDismissed = false;
      _status = AuthStatus.authenticated;
      _loading = false;
      notifyListeners();
      unawaited(_syncFcmToken());
      return true;
    } on GoogleSignInException catch (e) {
      _error = e.code == GoogleSignInExceptionCode.canceled
          ? null
          : 'Google sign-in failed. Please try again.';
      _loading = false;
      notifyListeners();
      return false;
    } on Exception catch (e) {
      _error = _parseError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// OTP-verifies [phone] for the current (Google) account. When the number
  /// already belongs to an existing account the backend merges the Google
  /// login into it and hands back that account's token — the session switches
  /// over here. Returns 'merged', 'verified', or null on failure ([error] set).
  Future<String?> verifyPhone({required String phone, required String otp}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await apiService.verifyPhone(phone, otp);
      final merged = data['merged'] == true;
      if (merged && data['token'] != null) {
        await StorageService.saveToken(data['token']);
      }
      _user = UserModel.fromJson(data['user']);
      _isNewUser = false;
      _loading = false;
      notifyListeners();
      if (merged) unawaited(_syncFcmToken());
      return merged ? 'merged' : 'verified';
    } on Exception catch (e) {
      _error = _parseError(e);
      _loading = false;
      notifyListeners();
      return null;
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
    // Extract the actual message from the API response body when available.
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final msg = data['message']?.toString() ?? data['error']?.toString();
        if (msg != null && msg.isNotEmpty) return msg;
      }
      final status = e.response?.statusCode;
      if (status == 422) return 'Validation error. Check your inputs.';
      if (status == 401) return 'Invalid credentials.';
    }
    final msg = e.toString();
    if (msg.contains('422')) return 'Validation error. Check your inputs.';
    if (msg.contains('401')) return 'Invalid credentials.';
    if (msg.contains('SocketException') || msg.contains('Connection')) {
      return 'No internet connection.';
    }
    return 'Something went wrong. Try again.';
  }
}
