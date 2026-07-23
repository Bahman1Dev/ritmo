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

String formatDuration(int minutes) {
  if (minutes < 60) {
    return '${toPersianDigits(minutes)} دقیقه';
  }
  final hours = minutes ~/ 60;
  final remaining = minutes % 60;
  if (remaining == 0) {
    return '${toPersianDigits(hours)} ساعت';
  }
  return '${toPersianDigits(hours)} ساعت و ${toPersianDigits(remaining)} دقیقه';
}
