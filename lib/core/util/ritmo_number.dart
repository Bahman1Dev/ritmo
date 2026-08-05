class RitmoNumber {
  const RitmoNumber._();

  static const List<String> _fa = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

  /// هر رقم لاتین داخل رشته را به رقم فارسی تبدیل می‌کند.
  static String fa(Object? input) {
    final s = input?.toString() ?? '';
    final buffer = StringBuffer();
    for (final code in s.runes) {
      if (code >= 0x30 && code <= 0x39) {
        buffer.write(_fa[code - 0x30]);
      } else {
        buffer.writeCharCode(code);
      }
    }
    return buffer.toString();
  }

  /// مثال: 62 -> ۶۲
  static String faInt(num value) => fa(value.round().toString());

  /// مثال: 62 -> ۶۲٪
  static String faPercent(num value) => '${faInt(value)}٪';

  /// مثال: 7.5 -> ۷٫۵ ساعت
  static String faHours(num hours) {
    final rounded = (hours * 10).round() / 10;
    final text = rounded % 1 == 0
        ? rounded.toInt().toString()
        : rounded.toStringAsFixed(1).replaceAll('.', '٫');
    return '${fa(text)} ساعت';
  }
}
