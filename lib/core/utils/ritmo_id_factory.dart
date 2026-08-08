class RitmoIdFactory {
  static String _stamp() {
    final now = DateTime.now();
    return '${now.millisecondsSinceEpoch}_${now.microsecondsSinceEpoch % 100000}';
  }

  static String routine() => 'routine_${_stamp()}';
  static String schedule(String routineId) => 'sched_${routineId}_${_stamp()}';
  static String goal() => 'goal_${_stamp()}';
  static String goalStep() => 'gs_${_stamp()}';
  static String worshipPractice() => 'wp_custom_${_stamp()}';
  static String worshipDebt() => 'wd_${_stamp()}';
  static String workoutLog() => 'wl_${_stamp()}';
  static String reflection(String dateIso) => 'reflection_$dateIso';

  // Completion & Log IDs
  static String konkurLog() => 'konkur_${_stamp()}';
  static String worshipLog() => 'worship_${_stamp()}';
  static String medicationLog() => 'med_${_stamp()}';
  static String completion() => 'comp_${_stamp()}';

  // Supplementary Sports IDs
  static String ssPlan() => 'ssplan_${_stamp()}';
  static String ssCrossRef() => 'ssxref_${_stamp()}';
  static String ssSession() => 'sssess_${_stamp()}';
  static String ssSetLog() => 'ssset_${_stamp()}';
  static String ssSchedule() => 'sssched_${_stamp()}';
  static String ssPr() => 'sspr_${_stamp()}';
  static String ssDecision() => 'ssdec_${_stamp()}';
  static String ssCustomExercise() => 'ssex_custom_${_stamp()}';
  static String ssPrescription(String dateIso) => 'pres_${dateIso}_${_stamp()}';

  // Movement Layer IDs
  static String movementLog() => 'mv_${_stamp()}';
  static String movementCustomKind(String slug) => 'mvk_custom_${slug}_${_stamp()}';
  static String movementPr() => 'mvpr_${_stamp()}';
}
