// lib/core/backend/appwrite_crash_service.dart

import 'package:appwrite/appwrite.dart';
import 'package:ritmo/core/backend/app_config.dart';
import 'package:ritmo/core/backend/models/auth_result.dart';
import 'package:ritmo/core/logging/ritmo_logger.dart';
import 'package:ritmo/core/observability/privacy_error_sink.dart';

class AppwriteCrashService {
  AppwriteCrashService._();
  static final AppwriteCrashService instance = AppwriteCrashService._();

  static const String databaseId = 'ritmo_db';
  static const String collectionId = 'crash_reports';

  Databases? _databases;

  void _initDatabases() {
    if (_databases == null && AppConfig.isAppwriteConfigured) {
      final client = Client()
          .setEndpoint(AppConfig.cleanEndpoint)
          .setProject(AppConfig.appwriteProjectId);
      _databases = Databases(client);
    }
  }

  /// Submits a privacy-sanitized crash report to Appwrite Database.
  /// All Farsi text & personal info are redacted before transmission.
  Future<AuthResult<bool>> submitSanitizedCrashReport({
    required String scope,
    required String exceptionType,
    required String sanitizedMessage,
    String? sanitizedStack,
  }) async {
    _initDatabases();
    if (_databases == null) {
      return const AuthResult.failure(AuthErrorCode.serverUnreachable);
    }

    try {
      final cleanMessage = PrivacyErrorSink.sanitize(sanitizedMessage);
      final cleanStack = sanitizedStack != null ? PrivacyErrorSink.sanitize(sanitizedStack) : null;

      await _databases!.createDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: ID.unique(),
        data: {
          'scope': scope,
          'exceptionType': exceptionType,
          'message': cleanMessage,
          'stackTrace': cleanStack ?? '',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      return const AuthResult.success(true);
    } on AppwriteException catch (e) {
      if (e.code == 401) {
        // Permissions not set on crash_reports table yet - suppress log noise
        return const AuthResult.failure(AuthErrorCode.unknown);
      }
      RitmoLog.error('AppwriteCrashService', 'Appwrite error sending crash report: ${e.message}');
      return const AuthResult.failure(AuthErrorCode.unknown);
    } catch (e, st) {
      RitmoLog.error('AppwriteCrashService', 'Failed to send crash report to server', e, st);
      return const AuthResult.failure(AuthErrorCode.unknown);
    }
  }
}
