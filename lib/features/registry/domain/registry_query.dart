// lib/features/registry/domain/registry_query.dart

import 'package:ritmo/features/registry/domain/registry_entry.dart';

enum RegistryLens { items, reminders, health }

enum RegistryGrouping { domain, timeOfDay, status, streak }

class RegistryQuery {
  const RegistryQuery({
    this.lens = RegistryLens.items,
    this.searchText = '',
    this.domainFilter = const {},
    this.statusFilter = const {RegistryStatus.active, RegistryStatus.paused},
    this.grouping = RegistryGrouping.domain,
    this.showArchived = false,
  });

  final RegistryLens lens;
  final String searchText;
  final Set<RegistryDomain> domainFilter; // Empty = All
  final Set<RegistryStatus> statusFilter;
  final RegistryGrouping grouping;
  final bool showArchived;

  RegistryQuery copyWith({
    RegistryLens? lens,
    String? searchText,
    Set<RegistryDomain>? domainFilter,
    Set<RegistryStatus>? statusFilter,
    RegistryGrouping? grouping,
    bool? showArchived,
  }) {
    return RegistryQuery(
      lens: lens ?? this.lens,
      searchText: searchText ?? this.searchText,
      domainFilter: domainFilter ?? this.domainFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      grouping: grouping ?? this.grouping,
      showArchived: showArchived ?? this.showArchived,
    );
  }
}
