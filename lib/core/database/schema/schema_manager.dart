import 'package:ritmo/core/database/schema/tables/ai_tables.dart';
import 'package:ritmo/core/database/schema/tables/assistant_tables.dart';
import 'package:ritmo/core/database/schema/tables/course_tables.dart';
import 'package:ritmo/core/database/schema/tables/cycle_tables.dart';
import 'package:ritmo/core/database/schema/tables/day_plan_tables.dart';
import 'package:ritmo/core/database/schema/tables/goal_tables.dart';
import 'package:ritmo/core/database/schema/tables/health_tables.dart';
import 'package:ritmo/core/database/schema/tables/konkur_tables.dart';
import 'package:ritmo/core/database/schema/tables/routine_tables.dart';
import 'package:ritmo/core/database/schema/tables/sports_tables.dart';
import 'package:ritmo/core/database/schema/tables/supplementary_sports_tables.dart';
import 'package:ritmo/core/database/schema/tables/system_tables.dart';
import 'package:ritmo/core/database/schema/tables/worship_tables.dart';
import 'package:ritmo/core/database/schema/tables/zone_tables.dart';
import 'package:sqflite/sqflite.dart';

class SchemaManager {
  static Future<void> createAll(Database db) async {
    await RoutineTables.create(db);
    await WorshipTables.create(db);
    await HealthTables.create(db);
    await CourseTables.create(db);
    await GoalTables.create(db);
    await ZoneTables.create(db);
    await CycleTables.create(db);
    await KonkurTables.create(db);
    await SportsTables.create(db);
    await SystemTables.create(db);
    await SupplementarySportsTables.create(db);
    await AssistantTables.create(db);
    await AiTables.create(db);
    await DayPlanTables.create(db);
  }
}
