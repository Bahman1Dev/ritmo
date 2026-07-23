enum CompletionResultType {
  full,
  light,
  minimal,
  skipped,
  cannotNow,
  snoozed,
  deferred;

  String get dbValue {
    switch (this) {
      case CompletionResultType.full:
        return 'FULL';
      case CompletionResultType.light:
        return 'LIGHT';
      case CompletionResultType.minimal:
        return 'MINIMAL';
      case CompletionResultType.skipped:
        return 'SKIPPED';
      case CompletionResultType.cannotNow:
        return 'CANNOT_NOW';
      case CompletionResultType.snoozed:
        return 'SNOOZED';
      case CompletionResultType.deferred:
        return 'DEFERRED';
    }
  }

  static CompletionResultType fromDb(String value) {
    switch (value.toUpperCase()) {
      case 'FULL':
        return CompletionResultType.full;
      case 'LIGHT':
        return CompletionResultType.light;
      case 'MINIMAL':
        return CompletionResultType.minimal;
      case 'SKIPPED':
        return CompletionResultType.skipped;
      case 'CANNOT_NOW':
        return CompletionResultType.cannotNow;
      case 'SNOOZED':
        return CompletionResultType.snoozed;
      case 'DEFERRED':
        return CompletionResultType.deferred;
      default:
        return CompletionResultType.full;
    }
  }
}

enum CompletionSource {
  user,
  system;

  String get dbValue {
    switch (this) {
      case CompletionSource.user:
        return 'USER';
      case CompletionSource.system:
        return 'SYSTEM';
    }
  }

  static CompletionSource fromDb(String value) {
    switch (value.toUpperCase()) {
      case 'USER':
        return CompletionSource.user;
      case 'SYSTEM':
        return CompletionSource.system;
      default:
        return CompletionSource.user;
    }
  }
}
