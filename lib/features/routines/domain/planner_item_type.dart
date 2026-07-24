enum PlannerItemType {
  routine('ROUTINE'),
  reminder('REMINDER'),
  task('TASK'),
  reflect('REFLECT'),
  event('EVENT'),
  goal('GOAL'),
  course('COURSE');

  const PlannerItemType(this.code);
  final String code;

  static PlannerItemType fromCode(String c) =>
      values.firstWhere((e) => e.code == c, orElse: () => routine);
}
