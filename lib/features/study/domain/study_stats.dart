import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:ritmo/core/util/ritmo_number.dart';

class StudyDate {
  const StudyDate._();

  static String formatRelative(String? isoDateStr) {
    if (isoDateStr == null || isoDateStr.isEmpty) return 'ثبت نشده';

    final dt = DateTime.tryParse(isoDateStr);
    if (dt == null) return isoDateStr;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);

    final diffDays = today.difference(target).inDays;

    if (diffDays == 0) return 'امروز';
    if (diffDays == 1) return 'دیروز';
    if (diffDays == -1) return 'فردا';
    if (diffDays > 1 && diffDays <= 7) return '${RitmoNumber.faInt(diffDays)} روز پیش';

    final jalali = Jalali.fromDateTime(dt);
    return '${RitmoNumber.faInt(jalali.day)} ${jalali.formatter.mN}';
  }
}
