import 'package:ritmo/core/domain/engines/routine_occurrence_generator.dart';
import 'package:sqflite/sqflite.dart';

class OccurrenceSyncService {
  const OccurrenceSyncService();

  Future<void> backfillAndGenerateAll(Database db) {
    return RoutineOccurrenceGenerator.backfillAndGenerateAll(db);
  }
}
