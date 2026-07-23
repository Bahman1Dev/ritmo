import 'package:shamsi_date/shamsi_date.dart';

String toPersianDigits(dynamic input) {
  if (input == null) return '';
  final str = input.toString();
  const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  var result = str;
  for (var i = 0; i < english.length; i++) {
    result = result.replaceAll(english[i], persian[i]);
  }
  return result;
}

String formatShamsiDate(String? dateIso) {
  if (dateIso == null || dateIso.isEmpty) return '';
  try {
    final dt = DateTime.parse(dateIso);
    final jalali = Jalali.fromDateTime(dt);
    return '${toPersianDigits(jalali.day)} ${jalali.formatter.mN} ${toPersianDigits(jalali.year)}';
  } catch (_) {
    return '';
  }
}
