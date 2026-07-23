// lib/core/platform/backup_platform.dart

abstract interface class BackupPlatform {
  /// Signs in to the remote cloud storage platform.
  Future<bool> signIn();

  /// Signs out from the cloud storage platform.
  Future<void> signOut();

  /// Returns true if currently signed in.
  bool get isSignedIn;

  /// Returns the signed-in user's email or identity identifier.
  String? get userEmail;

  /// Uploads an encrypted database backup using the provided passcode.
  Future<dynamic> uploadBackup(String passcode);

  /// Lists all remote backups available in the cloud folder.
  Future<List<dynamic>> listBackups();
}
