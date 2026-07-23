import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/features/assistant/models/day_plan_models.dart';
import 'package:uuid/uuid.dart';

class DayPlanTemplateService {
  DayPlanTemplateService._init();
  static final DayPlanTemplateService instance = DayPlanTemplateService._init();

  Future<DayPlanTemplate> saveTemplate({
    required String name,
    String? icon,
    required List<DayPlanItemDraft> items,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = 'template_${const Uuid().v4()}';

    final template = DayPlanTemplate(
      id: id,
      name: name,
      icon: icon,
      items: items,
      createdAt: now,
      updatedAt: now,
      lastUsedAt: now,
      useCount: 0,
    );

    await db.insert('day_plan_templates', template.toMap());
    return template;
  }

  Future<List<DayPlanTemplate>> getTemplates() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('day_plan_templates', orderBy: 'lastUsedAt DESC');
    return maps.map(DayPlanTemplate.fromMap).toList();
  }

  Future<DayPlanTemplate?> getTemplateByName(String name) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'day_plan_templates',
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return DayPlanTemplate.fromMap(maps.first);
  }

  Future<void> deleteTemplate(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('day_plan_templates', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> renameTemplate(String id, String newName) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'day_plan_templates',
      {
        'name': newName,
        'updatedAt': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> recordTemplateUsage(String id) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final list = await db.query('day_plan_templates', where: 'id = ?', whereArgs: [id], limit: 1);
    if (list.isNotEmpty) {
      final currentUseCount = list.first['useCount'] as int? ?? 0;
      await db.update(
        'day_plan_templates',
        {
          'lastUsedAt': now,
          'useCount': currentUseCount + 1,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }
}
