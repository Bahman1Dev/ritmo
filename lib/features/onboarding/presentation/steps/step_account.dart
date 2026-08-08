import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ritmo/core/backend/auth_service.dart';
import 'package:ritmo/core/theme/ritmo_colors.dart';
import 'package:ritmo/features/profile/presentation/widgets/otp_verification_sheet.dart';

class StepAccount extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const StepAccount({
    super.key,
    required this.onNext,
    required this.onSkip,
  });

  @override
  State<StepAccount> createState() => _StepAccountState();
}

class _StepAccountState extends State<StepAccount> {
  final AuthService _auth = AuthService.instance;
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _startPhoneLogin() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _errorMessage = 'لطفاً شماره تلفن همراه را وارد کنید.');
      return;
    }

    final normalized = AuthService.normalizeIranianPhone(phone);
    if (normalized == null) {
      setState(() => _errorMessage = 'شماره واردشده معتبر نیست (مثال: ۰۹۱۲۳۴۵۶۷۸۹).');
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
          onSuccess: widget.onNext,
        ),
      );
    } else {
      setState(() => _errorMessage = res.errorMessage);
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

    if (res.isSuccess) {
      widget.onNext();
    } else {
      setState(() => _errorMessage = res.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<RitmoColors>() ?? RitmoColors.light;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.shield_outlined, size: 48, color: colors.primary),
          const SizedBox(height: 16),
          Text(
            'ایجاد حساب کاربری (اختیاری)',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'می‌توانید همین حالا حساب بسازید یا بدون حساب ادامه دهید.',
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Phone Number input
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '۰۹۱۲۳۴۵۶۷۸۹',
              prefixIcon: Icon(Icons.phone_iphone, color: colors.textSecondary),
              filled: true,
              fillColor: colors.surfaceSunken,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _startPhoneLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.sms_outlined),
            label: _isLoading
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colors.onPrimary))
                : const Text('ارسال کد پیامکی', style: TextStyle(fontWeight: FontWeight.bold)),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: _isLoading ? null : _loginWithGoogle,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: colors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.account_circle, color: Colors.red),
            label: Text('ورود با حساب گوگل', style: TextStyle(color: colors.textPrimary)),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(_errorMessage!, style: TextStyle(color: colors.error, fontSize: 12), textAlign: TextAlign.center),
          ],

          const SizedBox(height: 20),

          TextButton(
            onPressed: widget.onSkip,
            child: Text('ادامه بدون حساب (مهمان)', style: TextStyle(fontSize: 15, color: colors.textSecondary)),
          ),
        ],
      ),
    );
  }
}
