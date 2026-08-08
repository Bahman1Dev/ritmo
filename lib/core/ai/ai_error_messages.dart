class AiErrorMessages {
  AiErrorMessages._();

  static String fa({
    int? statusCode,
    String? errorBody,
    String? exception,
  }) {
    if (errorBody != null) {
      if (errorBody.contains('4006') ||
          errorBody.toLowerCase().contains('daily free allocation') ||
          errorBody.toLowerCase().contains('quota exceeded')) {
        return 'سهمیهٔ رایگان امروز تمام شده. فردا دوباره فعال می‌شود.';
      }
    }

    if (statusCode != null) {
      if (statusCode == 401 || statusCode == 403) {
        return 'کلید نامعتبر است یا منقضی شده. کلید را دوباره از پنل سرویس‌دهنده کپی کنید.';
      }
      if (statusCode == 404) {
        return 'آدرس سرویس‌دهنده اشتباه است. معمولاً باید به /chat/completions ختم شود.';
      }
      if (statusCode == 429) {
        return 'سقف درخواست پر شده. چند دقیقه صبر کنید یا کلید پشتیبان تعریف کنید.';
      }
      if (statusCode == 400) {
        return 'نام مدل برای این سرویس‌دهنده معتبر نیست.';
      }
      if (statusCode >= 500 && statusCode <= 599) {
        return 'سرویس‌دهنده موقتاً در دسترس نیست.';
      }
    }

    if (exception != null) {
      final lower = exception.toLowerCase();
      if (lower.contains('timeoutexception') || lower.contains('timeout')) {
        return 'پاسخی دریافت نشد. احتمالاً این سرویس‌دهنده در شبکهٔ شما در دسترس نیست.';
      }
      if (lower.contains('socketexception') ||
          lower.contains('handshakeexception') ||
          lower.contains('connection refused') ||
          lower.contains('network is unreachable')) {
        return 'اتصال برقرار نشد. اینترنت یا دسترسی به این دامنه را بررسی کنید.';
      }
    }

    return 'خطای ناشناخته در ارتباط با سرویس‌دهنده.';
  }
}
