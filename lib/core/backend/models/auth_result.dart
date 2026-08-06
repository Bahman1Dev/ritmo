// lib/core/backend/models/auth_result.dart

enum AuthErrorCode {
  invalidPhone,
  wrongOtp,
  expiredOtp,
  maxAttemptsReached,
  smsDeliveryFailed,
  networkError,
  googleAuthCancelled,
  accountAlreadyLinked,
  serverUnreachable,
  unknown,
}

extension AuthErrorCodeExtension on AuthErrorCode {
  String get persianMessage {
    switch (this) {
      case AuthErrorCode.invalidPhone:
        return 'شماره تلفن واردشده معتبر نیست. لطفا شماره را به فرمت ۰۹۱۲xxxxxxx وارد کنید.';
      case AuthErrorCode.wrongOtp:
        return 'کد تأیید واردشده نادرست است.';
      case AuthErrorCode.expiredOtp:
        return 'کد تأیید منقضی شده است. لطفا مجددا درخواست کد دهید.';
      case AuthErrorCode.maxAttemptsReached:
        return 'تعداد تلاش‌های مجاز به پایان رسید. لطفا مجددا درخواست کد دهید.';
      case AuthErrorCode.smsDeliveryFailed:
        return 'ارسال پیامک با مشکل مواجه شد. می‌توانید از ورود با ایمیل استفاده کنید.';
      case AuthErrorCode.networkError:
        return 'خطا در ارتباط با سرور. لطفا اتصال اینترنت خود را بررسی کنید.';
      case AuthErrorCode.googleAuthCancelled:
        return 'ورود با گوگل لغو شد.';
      case AuthErrorCode.accountAlreadyLinked:
        return 'این حساب قبلا به کاربر دیگری پیوند خورده است.';
      case AuthErrorCode.serverUnreachable:
        return 'سرور در دسترس نیست. اپلیکیشن به صورت محلی به کار خود ادامه می‌دهد.';
      case AuthErrorCode.unknown:
        return 'خطایی در ارتباط با حساب کاربری رخ داد. لطفا دوباره تلاش کنید.';
    }
  }
}

class AuthResult<T> {
  final bool isSuccess;
  final T? data;
  final String? customMessage;
  final AuthErrorCode? errorCode;

  const AuthResult.success([this.data])
      : isSuccess = true,
        customMessage = null,
        errorCode = null;

  const AuthResult.failure(this.errorCode, [this.customMessage])
      : isSuccess = false,
        data = null;

  String? get errorMessage => customMessage ?? errorCode?.persianMessage;

  @override
  String toString() {
    return 'AuthResult(isSuccess: $isSuccess, data: $data, errorCode: $errorCode, errorMessage: $errorMessage)';
  }
}
