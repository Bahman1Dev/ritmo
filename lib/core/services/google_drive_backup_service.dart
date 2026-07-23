import 'dart:convert';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:ritmo/core/platform/backup_platform.dart';
import 'package:ritmo/core/services/backup_service.dart';

class GoogleDriveBackupService implements BackupPlatform {
  GoogleDriveBackupService._internal();
  static final GoogleDriveBackupService instance = GoogleDriveBackupService._internal();

  static const List<String> _scopes = [drive.DriveApi.driveAppdataScope];
  GoogleSignInAccount? _currentUser;

  // === Auth ===
  @override
  Future<bool> signIn() async {
    try {
      // Initialize first (required in google_sign_in v7.x)
      await GoogleSignIn.instance.initialize();
      // Try silent sign in first
      _currentUser = await GoogleSignIn.instance.attemptLightweightAuthentication();
      _currentUser ??= await GoogleSignIn.instance.authenticate(scopeHint: _scopes);
      return _currentUser != null;
    } catch (e) {
      debugPrint('Google Drive Sign-in Error: $e');
      return false;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
      _currentUser = null;
    } catch (e) {
      debugPrint('Google Drive Sign-out Error: $e');
    }
  }

  @override
  bool get isSignedIn => _currentUser != null;
  @override
  String? get userEmail => _currentUser?.email;

  // Helper to get authenticated DriveApi client
  Future<drive.DriveApi?> _getDriveApi() async {
    if (_currentUser == null) {
      final success = await signIn();
      if (!success || _currentUser == null) return null;
    }
    final authorization = await _currentUser!.authorizationClient.authorizationForScopes(_scopes);
    if (authorization == null) return null;
    final authClient = authorization.authClient(scopes: _scopes);
    return drive.DriveApi(authClient);
  }

  // === Backup ===
  /// Uploads an encrypted backup to appDataFolder.
  /// passcode is the user's chosen backup password (NOT the Google password).
  @override
  Future<BackupUploadResult> uploadBackup(String passcode) async {
    if (kIsWeb) {
      throw Exception('پشتیبان‌گیری در نسخه وب پشتیبانی نمی‌شود.');
    }
    final driveApi = await _getDriveApi();
    if (driveApi == null) {
      throw Exception('اتصال به حساب گوگل برقرار نشد.');
    }

    // 1. Export database to encrypted JSON string
    final backupJson = await BackupService.exportBackup(passcode);
    final bytes = utf8.encode(backupJson);
    final stream = Stream<List<int>>.value(bytes);

    // 2. Prepare metadata
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'ritmo_backup_$timestamp.json';

    final fileToUpload = drive.File();
    fileToUpload.name = fileName;
    fileToUpload.parents = ['appDataFolder'];
    fileToUpload.description = 'Ritmo secure encrypted backup';

    // 3. Upload
    final media = drive.Media(stream, bytes.length);
    final uploadedFile = await driveApi.files.create(
      fileToUpload,
      uploadMedia: media,
    );

    if (uploadedFile.id == null || uploadedFile.name == null) {
      throw Exception('آپلود فایل پشتیبان با خطا مواجه شد.');
    }

    return BackupUploadResult(
      fileId: uploadedFile.id!,
      fileName: uploadedFile.name!,
      sizeBytes: bytes.length,
      uploadedAt: DateTime.now(),
    );
  }

  /// Lists existing backups in appDataFolder.
  @override
  Future<List<RemoteBackupMetadata>> listBackups() async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) {
      throw Exception('اتصال به حساب گوگل برقرار نشد.');
    }

    final fileList = await driveApi.files.list(
      spaces: 'appDataFolder',
      orderBy: 'createdTime desc',
      $fields: 'files(id, name, size, createdTime, description)',
    );

    final backups = <RemoteBackupMetadata>[];
    if (fileList.files != null) {
      for (final file in fileList.files!) {
        if (file.name != null && file.name!.startsWith('ritmo_backup_') && file.name!.endsWith('.json')) {
          final sizeBytes = int.tryParse(file.size ?? '') ?? 0;
          final createdAt = file.createdTime ?? DateTime.now();
          backups.add(
            RemoteBackupMetadata(
              fileId: file.id!,
              fileName: file.name!,
              sizeBytes: sizeBytes,
              createdAt: createdAt,
              description: file.description,
            ),
          );
        }
      }
    }
    return backups;
  }

  /// Downloads a backup by fileId and restores it.
  Future<void> restoreFromCloud(String fileId, String passcode) async {
    if (kIsWeb) {
      throw Exception('پشتیبان‌گیری در نسخه وب پشتیبانی نمی‌شود.');
    }
    final driveApi = await _getDriveApi();
    if (driveApi == null) {
      throw Exception('اتصال به حساب گوگل برقرار نشد.');
    }

    // 1. Download file content
    final media = await driveApi.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
    
    // 2. Read bytes from stream
    final bytes = <int>[];
    await for (final chunk in media.stream) {
      bytes.addAll(chunk);
    }
    final backupJson = utf8.decode(bytes);

    // 3. Restore using BackupService
    await BackupService.restoreBackup(backupJson, passcode);
  }

  /// Deletes a specific backup.
  Future<void> deleteBackup(String fileId) async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) {
      throw Exception('اتصال به حساب گوگل برقرار نشد.');
    }
    await driveApi.files.delete(fileId);
  }

  /// Retention: keeps newest N, deletes the rest.
  Future<void> pruneOldBackups({int keepLast = 5}) async {
    try {
      final list = await listBackups();
      if (list.length > keepLast) {
        final toDelete = list.sublist(keepLast);
        for (final meta in toDelete) {
          await deleteBackup(meta.fileId);
        }
      }
    } catch (e) {
      debugPrint('Retention/pruning backups error: $e');
    }
  }
}

class BackupUploadResult {

  BackupUploadResult({
    required this.fileId,
    required this.fileName,
    required this.sizeBytes,
    required this.uploadedAt,
  });
  final String fileId;
  final String fileName;
  final int sizeBytes;
  final DateTime uploadedAt;
}

class RemoteBackupMetadata {

  RemoteBackupMetadata({
    required this.fileId,
    required this.fileName,
    required this.sizeBytes,
    required this.createdAt,
    this.description,
  });
  final String fileId;
  final String fileName;
  final int sizeBytes;
  final DateTime createdAt;
  final String? description;
}

class GoogleAuthClient extends http.BaseClient {
  GoogleAuthClient(this._headers);
  final Map<String, String> _headers;
  final http.Client _client = http.Client();
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}
