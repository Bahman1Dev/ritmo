// lib/core/backend/appwrite_gateway.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart' as models;
import 'package:ritmo/core/backend/app_config.dart';
import 'package:ritmo/core/backend/models/auth_result.dart';
import 'package:ritmo/core/logging/ritmo_logger.dart';

class AppwriteGateway {
  AppwriteGateway._();
  static final AppwriteGateway instance = AppwriteGateway._();

  Client? _client;
  Account? _account;
  Functions? _functions;
  bool _isInitialized = false;

  bool get isConfigured => AppConfig.isAppwriteConfigured;

  /// Initializes the Appwrite SDK asynchronously without blocking startup.
  Future<void> init() async {
    if (_isInitialized) return;
    if (!AppConfig.isAppwriteConfigured) {
      RitmoLog.info('AppwriteGateway', 'Appwrite is not configured via environment variables.');
      return;
    }

    try {
      final client = Client()
          .setEndpoint(AppConfig.cleanEndpoint)
          .setProject(AppConfig.appwriteProjectId);

      _client = client;
      _account = Account(client);
      _functions = Functions(client);
      _isInitialized = true;
      RitmoLog.info('AppwriteGateway', 'Appwrite Gateway initialized successfully.');
    } catch (e, st) {
      RitmoLog.error('AppwriteGateway', 'Failed to initialize Appwrite Gateway', e, st);
    }
  }

  /// Wraps any API call with timeout, exception mapping, and error translation.
  Future<AuthResult<T>> _safeCall<T>(Future<T> Function() call) async {
    if (!AppConfig.isAppwriteConfigured || !_isInitialized || _client == null) {
      return const AuthResult.failure(AuthErrorCode.serverUnreachable);
    }

    try {
      final result = await call().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Request timed out'),
      );
      return AuthResult.success(result);
    } on TimeoutException {
      return const AuthResult.failure(AuthErrorCode.networkError);
    } on AppwriteException catch (e) {
      RitmoLog.error('AppwriteGateway', 'AppwriteException: ${e.code} ${e.message}');
      return AuthResult.failure(_mapAppwriteError(e.code, e.type));
    } on SocketException {
      return const AuthResult.failure(AuthErrorCode.networkError);
    } catch (e, st) {
      RitmoLog.error('AppwriteGateway', 'Unexpected Gateway error', e, st);
      return const AuthResult.failure(AuthErrorCode.unknown);
    }
  }

  AuthErrorCode _mapAppwriteError(int? code, String? type) {
    if (code == 401 || type == 'user_invalid_credentials' || type == 'user_invalid_token') {
      return AuthErrorCode.wrongOtp;
    } else if (code == 429 || type == 'user_more_requests_than_limit') {
      return AuthErrorCode.maxAttemptsReached;
    } else if (code == 400 || type == 'user_phone_not_valid') {
      return AuthErrorCode.invalidPhone;
    } else if (type == 'user_already_exists' || type == 'user_phone_already_exists') {
      return AuthErrorCode.accountAlreadyLinked;
    } else if (code == 503 || code == 500) {
      return AuthErrorCode.serverUnreachable;
    }
    return AuthErrorCode.unknown;
  }

  /// Get current session/user if logged in.
  Future<AuthResult<models.User>> getCurrentUser() async {
    if (_account == null) return const AuthResult.failure(AuthErrorCode.serverUnreachable);
    return _safeCall(() => _account!.get());
  }

  /// Create OAuth2 session for Google.
  Future<AuthResult<bool>> loginWithGoogle() async {
    if (_account == null) return const AuthResult.failure(AuthErrorCode.serverUnreachable);
    return _safeCall(() async {
      await _account!.createOAuth2Session(
        provider: OAuthProvider.google,
      );
      return true;
    });
  }

  /// Execute core function for OTP request or verify.
  Future<AuthResult<String>> executeCoreFunction(Map<String, dynamic> payload) async {
    if (_functions == null) return const AuthResult.failure(AuthErrorCode.serverUnreachable);
    return _safeCall(() async {
      final execution = await _functions!.createExecution(
        functionId: AppConfig.appwriteFunctionId,
        body: jsonEncode(payload),
      );
      if (execution.status == 'failed') {
        throw AppwriteException(execution.responseBody, 500);
      }
      return execution.responseBody;
    });
  }

  /// Create session from custom token returned by OTP verify function.
  Future<AuthResult<models.Session>> createSessionWithToken(String userId, String secret) async {
    if (_account == null) return const AuthResult.failure(AuthErrorCode.serverUnreachable);
    return _safeCall(() => _account!.createSession(userId: userId, secret: secret));
  }

  /// Create email magic URL / token session.
  Future<AuthResult<models.Token>> createEmailToken(String userId, String email) async {
    if (_account == null) return const AuthResult.failure(AuthErrorCode.serverUnreachable);
    return _safeCall(() => _account!.createEmailToken(userId: userId, email: email));
  }

  /// Delete current session (Logout).
  Future<AuthResult<bool>> logout() async {
    if (_account == null) return const AuthResult.failure(AuthErrorCode.serverUnreachable);
    return _safeCall(() async {
      await _account!.deleteSession(sessionId: 'current');
      return true;
    });
  }
}
