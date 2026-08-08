enum TaskBucket { overdue, today, tomorrow, thisWeek, later, someday, doneToday }

extension TaskBucketX on TaskBucket {
  String get labelFa => switch (this) {
        TaskBucket.overdue => 'معوقه',
        TaskBucket.today => 'امروز',
        TaskBucket.tomorrow => 'فردا',
        TaskBucket.thisWeek => 'این هفته',
        TaskBucket.later => 'بعداً',
        TaskBucket.someday => 'بدون تاریخ',
        TaskBucket.doneToday => 'انجام‌شدهٔ امروز',
      };
}
