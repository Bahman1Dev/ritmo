// lib/core/backend/appwrite_backup_service.dart

import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:ritmo/core/backend/app_config.dart';
import 'package:ritmo/core/backend/appwrite_gateway.dart';
import 'package:ritmo/core/backend/models/auth_result.dart';
import 'package:ritmo/core/logging/ritmo_logger.dart';

class CloudBackupItem {
  final String id;
  final String name;
  final int sizeBytes;
  final DateTime createdAt;

  const CloudBackupItem({
    required this.id,
    required this.name,
    required this.sizeBytes,
    required this.createdAt,
  });
}

class AppwriteBackupService {
  AppwriteBackupService._();
  static final AppwriteBackupService instance = AppwriteBackupService._();

  static const String bucketId = 'ritmo_backups';

  Storage? _storage;

  void _initStorage() {
    if (_storage == null && AppConfig.isAppwriteConfigured) {
      final client = Client()
          .setEndpoint(AppConfig.cleanEndpoint)
          .setProject(AppConfig.appwriteProjectId);
      _storage = Storage(client);
    }
  }

  /// Uploads an encrypted .ritmo backup file to Appwrite Storage
  Future<AuthResult<CloudBackupItem>> uploadBackup(File ritmoFile) async {
    _initStorage();
    if (_storage == null) {
      return const AuthResult.failure(AuthErrorCode.serverUnreachable);
    }

    try {
      final fileName = 'backup_${DateTime.now().millisecondsSinceEpoch}.ritmo';
      final file = await _storage!.createFile(
        bucketId: bucketId,
        fileId: ID.unique(),
        file: InputFile.fromPath(path: ritmoFile.path, filename: fileName),
      );

      final item = CloudBackupItem(
        id: file.$id,
        name: file.name,
        sizeBytes: file.sizeOriginal,
        createdAt: DateTime.parse(file.$createdAt),
      );

      return AuthResult.success(item);
    } catch (e, st) {
      RitmoLog.error('AppwriteBackupService', 'Upload backup failed', e, st);
      return const AuthResult.failure(
        AuthErrorCode.unknown,
        'خطا در آپلود پشتیبان ابری.',
      );
    }
  }

  /// Lists all cloud backups for the current user from Appwrite Storage
  Future<AuthResult<List<CloudBackupItem>>> listBackups() async {
    _initStorage();
    if (_storage == null) {
      return const AuthResult.failure(AuthErrorCode.serverUnreachable);
    }

    try {
      final result = await _storage!.listFiles(bucketId: bucketId);
      final items = result.files
          .map((f) => CloudBackupItem(
                id: f.$id,
                name: f.name,
                sizeBytes: f.sizeOriginal,
                createdAt: DateTime.parse(f.$createdAt),
              ))
          .toList();

      return AuthResult.success(items);
    } catch (e, st) {
      RitmoLog.error('AppwriteBackupService', 'List backups failed', e, st);
      return const AuthResult.failure(
        AuthErrorCode.unknown,
        'خطا در دریافت لیست پشتیبان‌های ابری.',
      );
    }
  }

  /// Downloads a cloud backup file to a local destination path
  Future<AuthResult<File>> downloadBackup(String fileId, String destinationPath) async {
    _initStorage();
    if (_storage == null) {
      return const AuthResult.failure(AuthErrorCode.serverUnreachable);
    }

    try {
      final bytes = await _storage!.getFileDownload(
        bucketId: bucketId,
        fileId: fileId,
      );

      final localFile = File(destinationPath);
      await localFile.writeAsBytes(bytes);

      return AuthResult.success(localFile);
    } catch (e, st) {
      RitmoLog.error('AppwriteBackupService', 'Download backup failed', e, st);
      return const AuthResult.failure(
        AuthErrorCode.unknown,
        'خطا در دانلود پشتیبان ابری.',
      );
    }
  }
}
