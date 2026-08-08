import 'package:ritmo/core/domain/commands/ritmo_command.dart';
import 'package:ritmo/core/domain/commands/param_spec.dart';
import 'package:ritmo/core/domain/commands/command_plan.dart';
import 'package:ritmo/features/supplementary_sports/data/repositories/ss_prescription_repository.dart';
import 'package:ritmo/features/supplementary_sports/domain/prescription/session_prescription.dart';
import 'package:sqflite/sqflite.dart';

String _genId() => DateTime.now().microsecondsSinceEpoch.toString();

/// Mark today's workout session as done (skips to next day logic, links a workout_log_id)
class SportsMarkDoneCommand extends RitmoCommand {
  const SportsMarkDoneCommand();

  @override
  String get id => 'sports.mark_done';

  @override
  String get humanTitle => 'تمرین امروز را انجام شده علامت‌گذاری کن';

  @override
  String get humanDescriptionFa =>
      'وضعیت برنامه ورزشی امروز را به «انجام شده» تغییر می‌دهد. '
      'برای وقتی استفاده می‌شود که کاربر خارج از اپ تمرین کرده باشد.';

  @override
  Sensitivity get sensitivity => Sensitivity.confirm;

  @override
  Set<DataDomain> get touches => {DataDomain.sports};

  @override
  Map<String, ParamSpec> get params => {
    'dateStr': const ParamSpec(
      type: ParamType.isoDate,
      labelFa: 'تاریخ تمرین (پیش‌فرض امروز)',
      required: false,
    ),
    'durationMinutes': const ParamSpec(
      type: ParamType.integer,
      labelFa: 'مدت زمان تمرین به دقیقه',
      required: false,
      exampleFa: '45',
    ),
  };

  @override
  Future<PlanDiff> preview(AgentCommandContext ctx) async {
    final date = ctx.payload['dateStr']?.toString() ??
        DateTime.now().toIso8601String().split('T').first;
    final mins = ctx.payload['durationMinutes'] as int? ?? 45;
    return PlanDiff(
      kind: DiffKind.update,
      entityLabelFa: 'تمرین $date — $mins دقیقه انجام شد ✅',
    );
  }

  @override
  Future<CommandResult> run(AgentCommandContext ctx) async {
    final date = ctx.payload['dateStr']?.toString() ??
        DateTime.now().toIso8601String().split('T').first;

    final pres = await SsPrescriptionRepository.instance.getPrescriptionForDate(date);
    if (pres != null) {
      await SsPrescriptionRepository.instance.savePrescription(
        pres.copyWith(
          status: PrescriptionStatus.done,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }

    return CommandResult.ok(
      commandId: id,
      outputData: {'date': date},
      inverseData: {'date': date, 'prevStatus': pres?.status.code ?? 'PLANNED'},
    );
  }

  @override
  Future<CommandResult?> undo(
      AgentCommandContext ctx, Map<String, dynamic> inverseData) async {
    final date = inverseData['date']?.toString();
    final prevStatus = inverseData['prevStatus']?.toString() ?? 'PLANNED';
    if (date == null) return null;

    final pres = await SsPrescriptionRepository.instance.getPrescriptionForDate(date);
    if (pres != null) {
      await SsPrescriptionRepository.instance.savePrescription(
        pres.copyWith(
          status: PrescriptionStatus.fromCode(prevStatus),
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }
    return CommandResult.ok(commandId: id);
  }
}

/// Skip today's or a specific day's workout
class SportsSkipSessionCommand extends RitmoCommand {
  const SportsSkipSessionCommand();

  @override
  String get id => 'sports.skip_session';

  @override
  String get humanTitle => 'جلسه تمرین را رد کن';

  @override
  String get humanDescriptionFa =>
      'وضعیت برنامه ورزشی یک روز مشخص را به «رد شده» تغییر می‌دهد.';

  @override
  Sensitivity get sensitivity => Sensitivity.confirm;

  @override
  Set<DataDomain> get touches => {DataDomain.sports};

  @override
  Map<String, ParamSpec> get params => {
    'dateStr': const ParamSpec(
      type: ParamType.isoDate,
      labelFa: 'تاریخ جلسه (پیش‌فرض امروز)',
      required: false,
    ),
    'reason': const ParamSpec(
      type: ParamType.text,
      labelFa: 'دلیل رد شدن',
      required: false,
      exampleFa: 'بیماری',
    ),
  };

  @override
  Future<PlanDiff> preview(AgentCommandContext ctx) async {
    final date = ctx.payload['dateStr']?.toString() ??
        DateTime.now().toIso8601String().split('T').first;
    final reason = ctx.payload['reason']?.toString() ?? '';
    return PlanDiff(
      kind: DiffKind.delete,
      entityLabelFa: 'تمرین $date رد شد${reason.isNotEmpty ? " — $reason" : ""} 🚫',
    );
  }

  @override
  Future<CommandResult> run(AgentCommandContext ctx) async {
    final date = ctx.payload['dateStr']?.toString() ??
        DateTime.now().toIso8601String().split('T').first;

    final pres = await SsPrescriptionRepository.instance.getPrescriptionForDate(date);
    if (pres != null) {
      await SsPrescriptionRepository.instance.savePrescription(
        pres.copyWith(
          status: PrescriptionStatus.skipped,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }

    return CommandResult.ok(
      commandId: id,
      outputData: {'date': date},
      inverseData: {'date': date, 'prevStatus': pres?.status.code ?? 'PLANNED'},
    );
  }

  @override
  Future<CommandResult?> undo(
      AgentCommandContext ctx, Map<String, dynamic> inverseData) async {
    final date = inverseData['date']?.toString();
    final prevStatus = inverseData['prevStatus']?.toString() ?? 'PLANNED';
    if (date == null) return null;

    final pres = await SsPrescriptionRepository.instance.getPrescriptionForDate(date);
    if (pres != null) {
      await SsPrescriptionRepository.instance.savePrescription(
        pres.copyWith(
          status: PrescriptionStatus.fromCode(prevStatus),
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }
    return CommandResult.ok(commandId: id);
  }
}

/// Reschedule (move) a session from one date to another
class SportsMoveSessionCommand extends RitmoCommand {
  const SportsMoveSessionCommand();

  @override
  String get id => 'sports.move_session';

  @override
  String get humanTitle => 'جلسه تمرین را جابه‌جا کن';

  @override
  String get humanDescriptionFa =>
      'تمرین یک روز مشخص را به روز دیگری منتقل می‌کند. '
      'روز اصلی به «جابه‌جا شده» و روز مقصد به برنامه اضافه می‌شود.';

  @override
  Sensitivity get sensitivity => Sensitivity.confirm;

  @override
  Set<DataDomain> get touches => {DataDomain.sports};

  @override
  Map<String, ParamSpec> get params => {
    'fromDate': const ParamSpec(
      type: ParamType.isoDate,
      labelFa: 'تاریخ جلسه فعلی',
      required: true,
      exampleFa: '2026-08-08',
    ),
    'toDate': const ParamSpec(
      type: ParamType.isoDate,
      labelFa: 'تاریخ جدید',
      required: true,
      exampleFa: '2026-08-09',
    ),
  };

  @override
  Future<PlanDiff> preview(AgentCommandContext ctx) async {
    final from = ctx.payload['fromDate']?.toString() ?? '؟';
    final to = ctx.payload['toDate']?.toString() ?? '؟';
    return PlanDiff(
      kind: DiffKind.update,
      entityLabelFa: 'تمرین $from به $to منتقل شد 📅',
    );
  }

  @override
  Future<CommandResult> run(AgentCommandContext ctx) async {
    final from = ctx.payload['fromDate']?.toString();
    final to = ctx.payload['toDate']?.toString();
    if (from == null || to == null) {
      return CommandResult.failure(commandId: id, errorMessage: 'fromDate و toDate الزامی هستند.');
    }

    final repo = SsPrescriptionRepository.instance;
    final sourcePres = await repo.getPrescriptionForDate(from);

    if (sourcePres != null) {
      // Mark source as moved
      await repo.savePrescription(sourcePres.copyWith(
        status: PrescriptionStatus.moved,
        movedToDateIso: to,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ));

      // Create or update destination prescription
      final destPres = await repo.getPrescriptionForDate(to);
      if (destPres == null) {
        await repo.savePrescription(sourcePres.copyWith(
          id: 'pres_${to}_${DateTime.now().millisecondsSinceEpoch}',
          dateIso: to,
          status: PrescriptionStatus.planned,
          movedToDateIso: null,
          workoutLogId: null,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ));
      }
    }

    return CommandResult.ok(
      commandId: id,
      outputData: {'from': from, 'to': to},
      inverseData: {'from': from, 'to': to, 'sourceId': sourcePres?.id},
    );
  }

  @override
  Future<CommandResult?> undo(
      AgentCommandContext ctx, Map<String, dynamic> inverseData) async {
    final from = inverseData['from']?.toString();
    final to = inverseData['to']?.toString();
    if (from == null || to == null) return null;

    final repo = SsPrescriptionRepository.instance;
    final sourcePres = await repo.getPrescriptionForDate(from);
    if (sourcePres != null) {
      await repo.savePrescription(sourcePres.copyWith(
        status: PrescriptionStatus.planned,
        movedToDateIso: null,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ));
    }
    // Delete the moved prescription at destination
    final destPres = await repo.getPrescriptionForDate(to);
    if (destPres != null) {
      await repo.deletePrescriptionsBulk([destPres.id]);
    }
    return CommandResult.ok(commandId: id);
  }
}
