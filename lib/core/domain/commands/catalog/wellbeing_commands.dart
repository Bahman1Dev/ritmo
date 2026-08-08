import 'package:ritmo/core/domain/commands/ritmo_command.dart';
import 'package:ritmo/core/domain/commands/param_spec.dart';
import 'package:ritmo/core/domain/commands/command_plan.dart';
import 'package:sqflite/sqflite.dart';

String _genId() => DateTime.now().microsecondsSinceEpoch.toString();

class SleepLogCommand extends RitmoCommand {
  const SleepLogCommand();

  @override
  String get id => 'sleep.log';

  @override
  String get humanTitle => 'ثبت وضعیت خواب';

  @override
  String get humanDescriptionFa => 'ثبت زمان و کیفیت خواب شب گذشته جهت تحلیل خستگی';

  @override
  Sensitivity get sensitivity => Sensitivity.safe;

  @override
  Set<DataDomain> get touches => {DataDomain.sleep};

  @override
  Map<String, ParamSpec> get params => {
    'dateStr': const ParamSpec(
      type: ParamType.isoDate,
      labelFa: 'تاریخ ثبت (پیش‌فرض امروز)',
      required: false,
    ),
    'durationMinutes': const ParamSpec(
      type: ParamType.integer,
      labelFa: 'مدت خواب به دقیقه',
      required: true,
      exampleFa: '480',
    ),
    'quality': const ParamSpec(
      type: ParamType.integer,
      labelFa: 'کیفیت خواب (عدد بین ۱ تا ۵)',
      required: true,
      exampleFa: '3',
    ),
  };

  @override
  Future<PlanDiff> preview(AgentCommandContext ctx) async {
    final duration = ctx.payload['durationMinutes'] as int? ?? 480;
    final hours = (duration / 60).toStringAsFixed(1);
    return PlanDiff(kind: DiffKind.create, entityLabelFa: 'خواب: $hours ساعت');
  }

  @override
  Future<CommandResult> run(AgentCommandContext ctx) async {
    final date = ctx.payload['dateStr']?.toString() ?? DateTime.now().toIso8601String().split('T').first;
    final durationMinutes = ctx.payload['durationMinutes'] as int? ?? 480;
    final quality = ctx.payload['quality'] as int? ?? 3;

    await ctx.txn.insert('bedtime_diagnostics', {
      'date': date,
      'durationMinutes': durationMinutes,
      'quality': quality,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    return CommandResult.ok(commandId: id, outputData: {'date': date}, inverseData: {'date': date});
  }

  @override
  Future<CommandResult?> undo(AgentCommandContext ctx, Map<String, dynamic> inverseData) async {
    final date = inverseData['date']?.toString();
    if (date == null) return null;
    await ctx.txn.delete('bedtime_diagnostics', where: 'date = ?', whereArgs: [date]);
    return CommandResult.ok(commandId: id);
  }
}

class EnergyLogCommand extends RitmoCommand {
  const EnergyLogCommand();

  @override
  String get id => 'energy.log';

  @override
  String get humanTitle => 'ثبت سطح انرژی';

  @override
  String get humanDescriptionFa => 'ثبت میزان شارژ و انرژی بدنی جهت شخصی‌سازی روتین‌ها';

  @override
  Sensitivity get sensitivity => Sensitivity.safe;

  @override
  Set<DataDomain> get touches => {DataDomain.energy};

  @override
  Map<String, ParamSpec> get params => {
    'energyLevel': const ParamSpec(
      type: ParamType.enumeration,
      labelFa: 'سطح انرژی',
      required: true,
      allowed: ['HIGH', 'MEDIUM', 'LOW'],
    ),
    'note': const ParamSpec(
      type: ParamType.text,
      labelFa: 'یادداشت وضعیت',
      required: false,
    ),
  };

  @override
  Future<PlanDiff> preview(AgentCommandContext ctx) async {
    final level = ctx.payload['energyLevel']?.toString() ?? 'MEDIUM';
    final levelFa = level == 'HIGH' ? 'بالا' : (level == 'LOW' ? 'پایین' : 'متوسط');
    return PlanDiff(kind: DiffKind.create, entityLabelFa: 'ثبت انرژی: $levelFa');
  }

  @override
  Future<CommandResult> run(AgentCommandContext ctx) async {
    final logId = ctx.payload['id']?.toString() ?? _genId();
    final level = ctx.payload['energyLevel']?.toString() ?? 'MEDIUM';
    final note = ctx.payload['note']?.toString();

    await ctx.txn.insert('energy_logs', {
      'id': logId,
      'energyLevel': level,
      'source': 'COMMAND',
      'note': note,
      'loggedAt': DateTime.now().millisecondsSinceEpoch,
    });

    return CommandResult.ok(commandId: id, outputData: {'logId': logId}, inverseData: {'logId': logId});
  }

  @override
  Future<CommandResult?> undo(AgentCommandContext ctx, Map<String, dynamic> inverseData) async {
    final logId = inverseData['logId']?.toString();
    if (logId == null) return null;
    await ctx.txn.delete('energy_logs', where: 'id = ?', whereArgs: [logId]);
    return CommandResult.ok(commandId: id);
  }
}

class ReflectionLogCommand extends RitmoCommand {
  const ReflectionLogCommand();

  @override
  String get id => 'reflection.log';

  @override
  String get humanTitle => 'ثبت خودارزیابی';

  @override
  String get humanDescriptionFa => 'ثبت یادداشت و بازتاب از احوال روزانه خود';

  @override
  Sensitivity get sensitivity => Sensitivity.safe;

  @override
  Set<DataDomain> get touches => {DataDomain.reflection};

  @override
  Map<String, ParamSpec> get params => {
    'note': const ParamSpec(
      type: ParamType.text,
      labelFa: 'یادداشت ارزیابی',
      required: true,
      exampleFa: 'امروز حس بهتری داشتم و تمرکز عالی بود.',
    ),
    'mood': const ParamSpec(
      type: ParamType.enumeration,
      labelFa: 'خلق و خو',
      required: false,
      allowed: ['neutral', 'happy', 'sad', 'stressed', 'calm'],
    ),
  };

  @override
  Future<PlanDiff> preview(AgentCommandContext ctx) async {
    final note = ctx.payload['note']?.toString() ?? '';
    final summary = note.length > 30 ? '${note.substring(0, 30)}...' : note;
    return PlanDiff(kind: DiffKind.create, entityLabelFa: 'خودارزیابی: $summary');
  }

  @override
  Future<CommandResult> run(AgentCommandContext ctx) async {
    final idVal = ctx.payload['id']?.toString() ?? _genId();
    final mood = ctx.payload['mood']?.toString() ?? 'neutral';
    final note = ctx.payload['note']?.toString() ?? '';

    await ctx.txn.insert('mood_logs', {
      'id': idVal,
      'mood': mood,
      'valence': 3,
      'note': note,
      'loggedAt': DateTime.now().millisecondsSinceEpoch,
    });

    return CommandResult.ok(commandId: id, outputData: {'logId': idVal}, inverseData: {'logId': idVal});
  }

  @override
  Future<CommandResult?> undo(AgentCommandContext ctx, Map<String, dynamic> inverseData) async {
    final logId = inverseData['logId']?.toString();
    if (logId == null) return null;
    await ctx.txn.delete('mood_logs', where: 'id = ?', whereArgs: [logId]);
    return CommandResult.ok(commandId: id);
  }
}

class SettingUpdateCommand extends RitmoCommand {
  const SettingUpdateCommand();

  @override
  String get id => 'setting.update';

  @override
  String get humanTitle => 'تغییر تنظیمات برنامه';

  @override
  String get humanDescriptionFa => 'ویرایش و تغییر یکی از مقادیر تنظیمات کلیدی ریتمو';

  @override
  Sensitivity get sensitivity => Sensitivity.confirm;

  @override
  Set<DataDomain> get touches => const {};

  @override
  Map<String, ParamSpec> get params => {
    'key': const ParamSpec(
      type: ParamType.text,
      labelFa: 'کلید تنظیمات',
      required: true,
      exampleFa: 'assistant_cloud_consent',
    ),
    'value': const ParamSpec(
      type: ParamType.text,
      labelFa: 'مقدار جدید تنظیمات',
      required: true,
      exampleFa: 'true',
    ),
  };

  @override
  Future<PlanDiff> preview(AgentCommandContext ctx) async {
    final key = ctx.payload['key']?.toString() ?? '';
    final value = ctx.payload['value']?.toString() ?? '';
    return PlanDiff(kind: DiffKind.update, entityLabelFa: 'تنظیم $key', afterFa: value);
  }

  @override
  Future<CommandResult> run(AgentCommandContext ctx) async {
    final key = ctx.payload['key']?.toString();
    final value = ctx.payload['value']?.toString();
    if (key == null || value == null) {
      return CommandResult.failure(commandId: id, errorMessage: 'کلید یا مقدار تنظیمات نامعتبر است');
    }

    final existing = await ctx.txn.query('app_settings', where: 'key = ?', whereArgs: [key]);
    final oldValue = existing.isNotEmpty ? existing.first['value']?.toString() : null;

    await ctx.txn.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return CommandResult.ok(
      commandId: id,
      outputData: {'key': key, 'oldValue': oldValue, 'newValue': value},
      inverseData: {'key': key, 'oldValue': oldValue},
    );
  }

  @override
  Future<CommandResult?> undo(AgentCommandContext ctx, Map<String, dynamic> inverseData) async {
    final key = inverseData['key']?.toString();
    final oldValue = inverseData['oldValue']?.toString();
    if (key == null) return null;

    if (oldValue != null) {
      await ctx.txn.insert(
        'app_settings',
        {'key': key, 'value': oldValue},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      await ctx.txn.delete('app_settings', where: 'key = ?', whereArgs: [key]);
    }
    return CommandResult.ok(commandId: id);
  }
}
