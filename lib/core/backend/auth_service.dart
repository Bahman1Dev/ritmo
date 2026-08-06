// lib/core/backend/auth_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:ritmo/core/backend/appwrite_gateway.dart';
import 'package:ritmo/core/backend/models/auth_result.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/logging/ritmo_logger.dart';

class UserAccountState {
  final bool isLoggedIn;
  final String provider; // 'anonymous', 'phone', 'google', 'email'
  final String maskedIdentifier;
  final bool isGoogleLinked;

  const UserAccountState({
    required this.isLoggedIn,
    required this.provider,
    required this.maskedIdentifier,
    required this.isGoogleLinked,
  });

  factory UserAccountState.anonymous() => const UserAccountState(
        isLoggedIn: false,
        provider: 'anonymous',
        maskedIdentifier: '',
        isGoogleLinked: false,
      );
}

class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  final AppwriteGateway _gateway = AppwriteGateway.instance;
  UserAccountState _state = UserAccountState.anonymous();

  UserAccountState get state => _state;
  bool get isLoggedIn => _state.isLoggedIn;
  String get maskedIdentifier => _state.maskedIdentifier;
  String get provider => _state.provider;
  bool get isGoogleLinked => _state.isGoogleLinked;

  /// Normalizes Persian/Arabic numbers, removes non-digits, formats to +989xxxxxxxxx
  static String? normalizeIranianPhone(String raw) {
    if (raw.trim().isEmpty) return null;

    // Convert Persian & Arabic digits to ASCII
    const persianDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

    String s = raw.trim();
    for (int i = 0; i < 10; i++) {
      s = s.replaceAll(persianDigits[i], '$i').replaceAll(arabicDigits[i], '$i');
    }

    // Remove any character except + and digits
    s = s.replaceAll(RegExp(r'[^\d+]'), '');

    if (s.startsWith('+98')) {
      s = s.substring(3);
    } else if (s.startsWith('0098')) {
      s = s.substring(4);
    } else if (s.startsWith('0')) {
      s = s.substring(1);
    }

    // Iranian mobile numbers must be 10 digits starting with 9 (e.g. 9123456789)
    if (RegExp(r'^9\d{9}$').hasMatch(s)) {
      return '+98$s';
    }

    return null;
  }

  /// Masks phone number or email for display (e.g. +98912***3456)
  static String maskIdentifier(String identifier) {
    if (identifier.contains('@')) {
      final parts = identifier.split('@');
      if (parts[0].length <= 2) return identifier;
      return '${parts[0].substring(0, 2)}***@${parts[1]}';
    } else if (identifier.startsWith('+98')) {
      if (identifier.length < 13) return identifier;
      return '${identifier.substring(0, 6)}***${identifier.substring(10)}';
    }
    return identifier;
  }

  /// Non-blocking initialization of local account state & background SDK sync
  Future<void> init() async {
    await _loadStateFromLocalDb();
    // Background SDK warm-up
    unawaited(_gateway.init().then((_) => checkRemoteSession()));
  }

  Future<void> _loadStateFromLocalDb() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('app_settings');
      final map = <String, String>{};
      for (final r in rows) {
        map[r['key'] as String] = r['value'] as String;
      }

      final loggedIn = map['auth_logged_in'] == 'true';
      final provider = map['auth_provider'] ?? 'anonymous';
      final masked = map['auth_identifier_masked'] ?? '';
      final googleLinked = map['auth_google_linked'] == 'true';

      _state = UserAccountState(
        isLoggedIn: loggedIn,
        provider: provider,
        maskedIdentifier: masked,
        isGoogleLinked: googleLinked,
      );
      notifyListeners();
    } catch (e, st) {
      RitmoLog.error('AuthService', 'Error loading local auth state', e, st);
    }
  }

  Future<void> _saveStateToLocalDb({
    required bool loggedIn,
    required String provider,
    required String maskedIdentifier,
    required bool isGoogleLinked,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final batch = db.batch();
      batch.insert(
        'app_settings',
        {'key': 'auth_logged_in', 'value': loggedIn ? 'true' : 'false'},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      batch.insert(
        'app_settings',
        {'key': 'auth_provider', 'value': provider},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      batch.insert(
        'app_settings',
        {'key': 'auth_identifier_masked', 'value': maskedIdentifier},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      batch.insert(
        'app_settings',
        {'key': 'auth_google_linked', 'value': isGoogleLinked ? 'true' : 'false'},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await batch.commit(noResult: true);

      _state = UserAccountState(
        isLoggedIn: loggedIn,
        provider: provider,
        maskedIdentifier: maskedIdentifier,
        isGoogleLinked: isGoogleLinked,
      );
      notifyListeners();
    } catch (e, st) {
      RitmoLog.error('AuthService', 'Error saving local auth state', e, st);
    }
  }

  /// Verifies current remote session status quietly in background
  Future<void> checkRemoteSession() async {
    final result = await _gateway.getCurrentUser();
    if (result.isSuccess && result.data != null) {
      final user = result.data!;
      final phone = user.phone;
      final email = user.email;
      final rawId = phone.isNotEmpty ? phone : (email.isNotEmpty ? email : user.name);
      final masked = maskIdentifier(rawId);

      await _saveStateToLocalDb(
        loggedIn: true,
        provider: phone.isNotEmpty ? 'phone' : (email.isNotEmpty ? 'email' : 'google'),
        maskedIdentifier: masked,
        isGoogleLinked: email.contains('@gmail.com') || _state.isGoogleLinked,
      );
    }
  }

  /// Flow 1: Continue as Guest
  Future<void> continueAsGuest() async {
    await _saveStateToLocalDb(
      loggedIn: false,
      provider: 'anonymous',
      maskedIdentifier: '',
      isGoogleLinked: false,
    );
  }

  /// Flow 2: Request Phone OTP
  Future<AuthResult<bool>> requestPhoneOtp(String rawPhone) async {
    final normalized = normalizeIranianPhone(rawPhone);
    if (normalized == null) {
      return const AuthResult.failure(AuthErrorCode.invalidPhone);
    }

    final res = await _gateway.executeCoreFunction({
      'action': 'otp/request',
      'phone': normalized,
    });
    if (!res.isSuccess) return AuthResult.failure(res.errorCode, res.errorMessage);

    return const AuthResult.success(true);
  }

  /// Flow 2: Verify Phone OTP
  Future<AuthResult<bool>> verifyPhoneOtp(String rawPhone, String otpCode) async {
    final normalized = normalizeIranianPhone(rawPhone);
    if (normalized == null) {
      return const AuthResult.failure(AuthErrorCode.invalidPhone);
    }

    if (otpCode.trim().length != 6) {
      return const AuthResult.failure(AuthErrorCode.wrongOtp);
    }

    final res = await _gateway.executeCoreFunction({
      'action': 'otp/verify',
      'phone': normalized,
      'code': otpCode.trim(),
    });
    if (!res.isSuccess) return AuthResult.failure(res.errorCode, res.errorMessage);

    try {
      final responseData = jsonDecode(res.data ?? '{}') as Map<String, dynamic>;
      final userId = responseData['userId'] as String?;
      final secret = responseData['secret'] as String?;

      if (userId != null && secret != null) {
        final sessionRes = await _gateway.createSessionWithToken(userId, secret);
        if (!sessionRes.isSuccess) {
          return AuthResult.failure(sessionRes.errorCode, sessionRes.errorMessage);
        }
      }

      await _saveStateToLocalDb(
        loggedIn: true,
        provider: 'phone',
        maskedIdentifier: maskIdentifier(normalized),
        isGoogleLinked: _state.isGoogleLinked,
      );

      return const AuthResult.success(true);
    } catch (e, st) {
      RitmoLog.error('AuthService', 'OTP verify response parse error', e, st);
      return const AuthResult.failure(AuthErrorCode.unknown);
    }
  }

  /// Flow 3: Google Login
  Future<AuthResult<bool>> loginWithGoogle() async {
    final res = await _gateway.loginWithGoogle();
    if (res.isSuccess) {
      await checkRemoteSession();
    }
    return res;
  }

  /// Flow 4: Email OTP (Fallback)
  Future<AuthResult<String>> requestEmailOtp(String email) async {
    if (!email.contains('@') || !email.contains('.')) {
      return const AuthResult.failure(AuthErrorCode.invalidPhone, 'ایمیل واردشده معتبر نیست.');
    }
    final res = await _gateway.createEmailToken('unique()', email.trim());
    if (!res.isSuccess || res.data == null) return AuthResult.failure(res.errorCode, res.errorMessage);
    return AuthResult.success(res.data!.userId);
  }

  Future<AuthResult<bool>> verifyEmailOtp(String userId, String secret) async {
    final res = await _gateway.createSessionWithToken(userId, secret.trim());
    if (!res.isSuccess) return AuthResult.failure(res.errorCode, res.errorMessage);
    await checkRemoteSession();
    return const AuthResult.success(true);
  }

  /// Logout (Preserves local SQLite data completely!)
  Future<AuthResult<bool>> logout() async {
    final res = await _gateway.logout();
    await _saveStateToLocalDb(
      loggedIn: false,
      provider: 'anonymous',
      maskedIdentifier: '',
      isGoogleLinked: false,
    );
    return res.isSuccess ? const AuthResult.success(true) : AuthResult.failure(res.errorCode, res.errorMessage);
  }
}
