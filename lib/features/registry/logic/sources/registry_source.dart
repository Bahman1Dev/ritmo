// lib/features/registry/logic/sources/registry_source.dart

import 'package:ritmo/features/registry/domain/registry_entry.dart';

abstract class RegistrySource {
  RegistryDomain get domain;

  /// Returns settings key string, e.g. 'module_courses_enabled'. Empty string means always enabled.
  String get moduleSettingsKey;

  Future<int> count({bool includeArchived = false});

  Future<List<RegistryEntry>> fetch({
    required int limit,
    required int offset,
    bool includeArchived = false,
  });
}
