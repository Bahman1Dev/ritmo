class PersianDigits {
  static String convert(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var result = input;
    for (var i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], persian[i]);
    }
    return result;
  }
}

String toPersianDigits(Object? input) => PersianDigits.convert(input?.toString() ?? '');

extension PersianDigitsExtension on Object {
  String toPersianDigits() => PersianDigits.convert(toString());
}
