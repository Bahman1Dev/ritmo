// lib/features/profile/presentation/account_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/backend/auth_service.dart';
import 'package:ritmo/core/backend/models/auth_result.dart';
import 'package:ritmo/core/theme/ritmo_colors.dart';
import 'package:ritmo/features/profile/presentation/widgets/otp_verification_sheet.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> with WidgetsBindingObserver {
  final AuthService _auth = AuthService.instance;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _isPhoneValid = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _auth.addListener(_onAuthChanged);
    _phoneController.addListener(_validatePhoneInput);

    // Initial check for remote session on screen open
    _auth.checkRemoteSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _auth.removeListener(_onAuthChanged);
    _phoneController.removeListener(_validatePhoneInput);
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// Automatically trigger remote session check when user returns from browser (OAuth)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _auth.checkRemoteSession();
    }
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  void _validatePhoneInput() {
    final normalized = AuthService.normalizeIranianPhone(_phoneController.text);
    final isValid = normalized != null;
    if (isValid != _isPhoneValid) {
      setState(() => _isPhoneValid = isValid);
    }
  }

  Future<void> _startPhoneLogin() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _errorMessage = 'لطفاً شماره تلفن همراه خود را وارد کنید.');
      return;
    }

    final normalized = AuthService.normalizeIranianPhone(phone);
    if (normalized == null) {
      setState(() => _errorMessage = AuthErrorCode.invalidPhone.persianMessage);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _auth.requestPhoneOtp(normalized);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.isSuccess) {
      unawaited(
        OtpVerificationSheet.show(
          context,
          identifier: normalized,
          onSuccess: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.white),
                    SizedBox(width: 8),
                    Text('با موفقیت وارد حساب کاربری شدید.'),
                  ],
                ),
                backgroundColor: const Color(0xff10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          },
        ),
      );
    } else {
      setState(() => _errorMessage = res.errorMessage ?? AuthErrorCode.unknown.persianMessage);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _auth.loginWithGoogle();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!res.isSuccess) {
      setState(() => _errorMessage = res.errorMessage ?? AuthErrorCode.googleAuthCancelled.persianMessage);
    }
  }

  Future<void> _startEmailLogin() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'لطفاً یک نشانی ایمیل معتبر وارد کنید.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _auth.requestEmailOtp(email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.isSuccess && res.data != null) {
      unawaited(
        OtpVerificationSheet.show(
          context,
          identifier: email,
          isEmail: true,
          emailUserId: res.data,
          onSuccess: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.white),
                    SizedBox(width: 8),
                    Text('با موفقیت از طریق ایمیل وارد حساب کاربری شدید.'),
                  ],
                ),
                backgroundColor: const Color(0xff10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          },
        ),
      );
    } else {
      setState(() => _errorMessage = res.errorMessage ?? AuthErrorCode.unknown.persianMessage);
    }
  }

  Future<void> _confirmLogout() async {
    final colors = Theme.of(context).extension<RitmoColors>() ?? RitmoColors.light;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('خروج از حساب کاربری'),
            ],
          ),
          content: const Text(
            'آیا از خروج از حساب کاربری اطمینان دارید؟\n\n'
            '🔒 داده‌ها و روتین‌های ذخیره‌شده روی این دستگاه به‌هیچ‌عنوان پاک نخواهند شد.',
            style: TextStyle(height: 1.6),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('انصراف', style: TextStyle(color: colors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('خروج از حساب'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      await _auth.logout();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('از حساب کاربری خارج شدید.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<RitmoColors>() ?? RitmoColors.light;
    final isLoggedIn = _auth.isLoggedIn;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: const Text('حساب کاربری', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Notice Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: colors.warning, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'همگام‌سازی ابری به‌زودی فعال می‌شود. داده‌های فعلی شما به صورت امن روی همین دستگاه محفوظ است.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textPrimary,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Glassmorphic User Status Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: isLoggedIn
                              ? [const Color(0xff10B981), const Color(0xff059669)]
                              : [Colors.grey.shade400, Colors.grey.shade600],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: colors.surface,
                        child: Icon(
                          isLoggedIn ? Icons.person_rounded : Icons.person_outline_rounded,
                          size: 40,
                          color: isLoggedIn ? const Color(0xff10B981) : colors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isLoggedIn ? 'حساب کاربری فعال' : 'حساب غیرفعال (کاربر مهمان)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (isLoggedIn) ...[
                      const SizedBox(height: 6),
                      Text(
                        _auth.maskedIdentifier,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        textDirection: TextDirection.ltr,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _auth.provider == 'phone'
                                  ? Icons.phone_android_rounded
                                  : (_auth.provider == 'google'
                                      ? Icons.g_mobiledata_rounded
                                      : Icons.email_rounded),
                              size: 18,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'روش ورود: ${_auth.provider == 'phone' ? 'شماره همراه' : (_auth.provider == 'google' ? 'گوگل (OAuth)' : 'ایمیل')}',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (!isLoggedIn) ...[
                Text(
                  'ورود یا ایجاد حساب کاربری',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // Phone Input Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.phone_android_rounded, color: colors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'ورود با شماره تلفن همراه',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textDirection: TextDirection.ltr,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9+۰-۹٠-٩\s-]')),
                        ],
                        decoration: InputDecoration(
                          hintText: '۰۹۱۲ ۳۴۵ ۶۷۸۹',
                          hintTextDirection: TextDirection.rtl,
                          filled: true,
                          fillColor: colors.surfaceSunken,
                          prefixIcon: _isPhoneValid
                              ? const Icon(Icons.check_circle_rounded, color: Color(0xff10B981))
                              : Icon(Icons.phone_iphone_rounded, color: colors.textSecondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: colors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: colors.primary, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _startPhoneLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: colors.onPrimary,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.sms_rounded, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'ارسال کد تأیید پیامکی',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Google Login Button
                SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _loginWithGoogle,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: colors.surface,
                      side: BorderSide(color: colors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                          width: 22,
                          height: 22,
                          errorBuilder: (_, __, ___) => const Icon(Icons.account_circle, color: Colors.red),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'ورود سریع با حساب گوگل (OAuth)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Email Fallback Expansion
                Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.border),
                  ),
                  child: ExpansionTile(
                    shape: const Border(),
                    leading: Icon(Icons.email_outlined, color: colors.textSecondary),
                    title: Text(
                      'ورود با ایمیل (مسیر پشتیبان)',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textDirection: TextDirection.ltr,
                              decoration: InputDecoration(
                                hintText: 'example@gmail.com',
                                filled: true,
                                fillColor: colors.surfaceSunken,
                                prefixIcon: Icon(Icons.alternate_email_rounded, color: colors.textSecondary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _startEmailLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.surfaceElevated,
                                foregroundColor: colors.textPrimary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('ارسال لینک/کد به ایمیل'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded, color: colors.error, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: colors.error, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else ...[
                // Logged in Logout Button
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _confirmLogout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.shade700,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text(
                      'خروج از حساب کاربری',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
