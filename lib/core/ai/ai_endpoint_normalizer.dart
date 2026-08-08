class AiEndpointNormalizer {
  AiEndpointNormalizer._();

  /// ورودی خام کاربر را به endpoint کامل chat/completions تبدیل می‌کند.
  static String normalize(String raw, {bool allowHttp = false}) {
    var trimmed = raw.trim();
    if (trimmed.isEmpty) return '';

    // Strip trailing slashes
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1).trim();
    }

    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'https://$trimmed';
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return trimmed;

    final path = uri.path;
    if (path.endsWith('/chat/completions') || path == '/chat/completions') {
      return trimmed;
    }

    if (path.endsWith('/v1') || path == '/v1') {
      return '$trimmed/chat/completions';
    }

    if (path.isEmpty || path == '/') {
      return '$trimmed/v1/chat/completions';
    }

    return '$trimmed/chat/completions';
  }

  /// اگر آدرس غیرقابل‌استفاده است، پیام خطای فارسی برمی‌گرداند؛ وگرنه null.
  static String? validate(String raw, {bool allowHttp = false}) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return 'آدرس سرویس‌دهنده را وارد کنید';
    }

    if (trimmed.contains('{ACCOUNT_ID}') || trimmed.contains('YOUR_ACCOUNT_ID')) {
      return 'شناسهٔ حساب Cloudflare را جایگزین کنید';
    }

    var effective = trimmed;
    if (!effective.startsWith('http://') && !effective.startsWith('https://')) {
      effective = 'https://$effective';
    }

    final uri = Uri.tryParse(effective);
    if (uri == null || uri.host.isEmpty || !uri.host.contains('.')) {
      if (uri?.host != 'localhost') {
        return 'آدرس معتبر نیست';
      }
    }

    if (uri != null && uri.scheme == 'http') {
      final isLocal = uri.host == 'localhost' ||
          uri.host == '127.0.0.1' ||
          uri.host == '10.0.2.2';
      if (!allowHttp && !isLocal) {
        return 'فقط آدرس امن (https) پذیرفته می‌شود';
      }
    }

    return null;
  }
}
