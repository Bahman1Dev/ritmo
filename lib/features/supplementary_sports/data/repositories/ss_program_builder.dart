import 'package:ritmo/features/supplementary_sports/data/models/ss_user_profile_model.dart';
import 'package:ritmo/features/supplementary_sports/domain/prescription/session_prescription.dart';
import 'package:ritmo/features/supplementary_sports/domain/prescription/muscle_group.dart';
import 'package:ritmo/features/supplementary_sports/domain/prescription/split_pattern.dart';
import 'package:ritmo/features/supplementary_sports/domain/ss_program_calendar.dart';
import 'package:ritmo/features/supplementary_sports/data/repositories/ss_prescription_repository.dart';

class ProgramBuildRequest {
  const ProgramBuildRequest({
    required this.fromDate,
    this.weeksToBuild = 4,
    required this.profile,
    this.respectLocks = true,
  });

  final DateTime fromDate;
  final int weeksToBuild;
  final SsUserProfile profile;
  final bool respectLocks;
}

class ProgramBuildResult {
  const ProgramBuildResult({
    required this.created,
    required this.replaced,
    required this.untouched,
    required this.warningsFa,
  });

  final List<SessionPrescription> created;
  final List<SessionPrescription> replaced;
  final List<SessionPrescription> untouched;
  final List<String> warningsFa;
}

class SsProgramBuilder {
  static Future<ProgramBuildResult> preview(ProgramBuildRequest req) async {
    final profile = req.profile;
    final startNormalized = req.fromDate;
    final totalDays = req.weeksToBuild * 7;
    
    final created = <SessionPrescription>[];
    final replaced = <SessionPrescription>[];
    final untouched = <SessionPrescription>[];
    final warningsFa = <String>[];
    
    // Parse start date
    DateTime programStart = startNormalized;
    if (profile.programStartDate != null && profile.programStartDate!.isNotEmpty) {
      try {
        programStart = DateTime.parse(profile.programStartDate!);
      } catch (_) {}
    }
    
    final repo = SsPrescriptionRepository.instance;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    
    // Determine session minutes based on profile duration
    int defaultMinutes = 45;
    if (profile.sessionDuration == SessionDuration.short30) {
      defaultMinutes = 30;
    } else if (profile.sessionDuration == SessionDuration.long60) {
      defaultMinutes = 60;
    }
    
    // Convert trainingDays set
    final trainingDays = profile.trainingDays.toSet();
    
    for (int d = 0; d < totalDays; d++) {
      final date = startNormalized.add(Duration(days: d));
      final dateIso = date.toIso8601String().substring(0, 10);
      final dow = SsProgramCalendar.ritmoDayOf(date);
      final cycleWeek = SsProgramCalendar.cycleWeekFor(date, programStart: programStart);
      
      final isTrainingDay = trainingDays.contains(dow);
      final isDeload = SsProgramCalendar.isDeloadWeek(cycleWeek, deloadEveryNWeeks: profile.deloadEveryNWeeks);
      
      final sortedWeekdays = [6, 7, 1, 2, 3, 4, 5];
      final sortedTrainingDays = sortedWeekdays.where(trainingDays.contains).toList();
      final sessionIndexInWeek = sortedTrainingDays.indexOf(dow);
      
      final existing = await repo.getPrescriptionForDate(dateIso);
      if (req.respectLocks && existing != null) {
        if (existing.isLocked || existing.source != 'GENERATED' || existing.status != PrescriptionStatus.planned) {
          untouched.add(existing);
          continue;
        }
      }
      
      final SlotType slotType;
      final List<String> focus;
      final int targetMinutes;
      final IntensityTier intensity;
      
      if (!isTrainingDay) {
        slotType = SlotType.rest;
        focus = [];
        targetMinutes = 0;
        intensity = IntensityTier.moderate;
      } else {
        slotType = SlotType.strength;
        focus = SplitPattern.focusFor(
          profile.splitPattern,
          sessionIndexInWeek >= 0 ? sessionIndexInWeek : 0,
          profile.focusAreas.map((f) => f.name.toUpperCase()).toList(),
        );
        
        if (isDeload) {
          intensity = IntensityTier.light;
          targetMinutes = (defaultMinutes * 0.7).round();
        } else {
          intensity = IntensityTier.fromCode(profile.defaultIntensity);
          targetMinutes = defaultMinutes;
        }
      }
      
      final headline = MuscleGroup.buildHeadline(targetMinutes, focus, slotType);
      
      String? coachNote;
      if (slotType == SlotType.rest) {
        coachNote = 'امروز روز استراحت و ریکاوری بدن شماست. آب کافی بنوشید.';
      } else {
        final focusNames = focus.map((c) => MuscleGroup.taxonomy[c]?.titleFa ?? c).join(' و ');
        coachNote = isDeload 
            ? 'هفته ریکاوری سبک. تمرکز بر روی تکنیک حرکات و کاهش فشار بر روی $focusNames.'
            : 'جلسه تمرینی متمرکز بر روی $focusNames. انرژی خود را حفظ کنید و با تمرکز بالا ادامه دهید.';
      }
      
      final p = SessionPrescription(
        id: existing?.id ?? 'pres_${dateIso}_${nowMs}_${d}',
        dateIso: dateIso,
        cycleWeek: cycleWeek,
        slotType: slotType,
        focusCodes: focus,
        targetMinutes: targetMinutes,
        intensityTier: intensity,
        targetRpe: intensity.targetRpe,
        headlineFa: headline,
        coachNoteFa: coachNote,
        source: 'GENERATED',
        isLocked: existing?.isLocked ?? false,
        status: existing?.status ?? PrescriptionStatus.planned,
        movedToDateIso: existing?.movedToDateIso,
        legacyPlanId: existing?.legacyPlanId,
        workoutLogId: existing?.workoutLogId,
        createdAt: existing?.createdAt ?? nowMs,
        updatedAt: nowMs,
      );
      
      if (existing != null) {
        replaced.add(p);
      } else {
        created.add(p);
      }
    }
    
    return ProgramBuildResult(
      created: created,
      replaced: replaced,
      untouched: untouched,
      warningsFa: warningsFa,
    );
  }

  static Future<ProgramBuildResult> apply(ProgramBuildRequest req) async {
    final res = await preview(req);
    final repo = SsPrescriptionRepository.instance;
    
    final toSave = [...res.created, ...res.replaced];
    await repo.savePrescriptionsBulk(toSave);
    
    return res;
  }
}
