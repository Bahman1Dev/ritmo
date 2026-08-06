// lib/features/profile/presentation/widgets/otp_verification_sheet.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/backend/auth_service.dart';
import 'package:ritmo/core/backend/models/auth_result.dart';
import 'package:ritmo/core/theme/ritmo_colors.dart';

class OtpVerificationSheet extends StatefulWidget {
  final String identifier;
  final bool isEmail;
  final String? emailUserId;
  final VoidCallback onSuccess;

  const OtpVerificationSheet({
    super.key,
    required this.identifier,
    this.isEmail = false,
    this.emailUserId,
    required this.onSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required String identifier,
    bool isEmail = false,
    String? emailUserId,
    required VoidCallback onSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: OtpVerificationSheet(
          identifier: identifier,
          isEmail: isEmail,
          emailUserId: emailUserId,
          onSuccess: onSuccess,
        ),
      ),
    );
  }

  @override
  State<OtpVerificationSheet> createState() => _OtpVerificationSheetState();
}

class _OtpVerificationSheetState extends State<OtpVerificationSheet> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _timer;
  int _secondsRemaining = 120;
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _secondsRemaining = 120;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        t.cancel();
      }
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');
    return '$mStr:$sStr';
  }

  String _normalizeDigits(String input) {
    const persianDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String res = input;
    for (int i = 0; i < 10; i++) {
      res = res.replaceAll(persianDigits[i], '$i').replaceAll(arabicDigits[i], '$i');
    }
    return res.replaceAll(RegExp(r'[^\d]'), '');
  }

  Future<void> _verifyCode() async {
    final code = _normalizeDigits(_otpController.text);
    if (code.length != 6) {
      setState(() => _errorMessage = 'لطفاً کد ۶ رقمی کامل را وارد کنید.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final AuthResult<bool> res;
    if (widget.isEmail) {
      if (widget.emailUserId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'شناسه تأیید ایمیل معتبر نیست. لطفاً مجدداً تلاش کنید.';
        });
        return;
      }
      res = await AuthService.instance.verifyEmailOtp(widget.emailUserId!, code);
    } else {
      res = await AuthService.instance.verifyPhoneOtp(widget.identifier, code);
    }

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (res.isSuccess) {
      Navigator.of(context).pop();
      widget.onSuccess();
    } else {
      setState(() {
        _errorMessage = res.errorMessage ?? AuthErrorCode.wrongOtp.persianMessage;
      });
    }
  }

  Future<void> _resendCode() async {
    if (_secondsRemaining > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    final AuthResult<dynamic> res;
    if (widget.isEmail) {
      res = await AuthService.instance.requestEmailOtp(widget.identifier);
    } else {
      res = await AuthService.instance.requestPhoneOtp(widget.identifier);
    }

    if (!mounted) return;

    setState(() => _isResending = false);

    if (res.isSuccess) {
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.mark_chat_read_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('کد تأیید جدید ارسال شد.'),
            ],
          ),
          backgroundColor: const Color(0xff10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      setState(() {
        _errorMessage = res.errorMessage ?? AuthErrorCode.smsDeliveryFailed.persianMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<RitmoColors>() ?? RitmoColors.light;
    final maskedId = AuthService.maskIdentifier(widget.identifier);
    final rawDigits = _normalizeDigits(_otpController.text);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: colors.divider,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.isEmail ? 'تأیید نشانی ایمیل' : 'تأیید شماره همراه',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                  height: 1.5,
                ),
                children: [
                  TextSpan(text: widget.isEmail ? 'کد ۶ رقمی ارسال‌شده به ایمیل ' : 'کد ۶ رقمی ارسال‌شده به شماره '),
                  TextSpan(
                    text: maskedId,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                  const TextSpan(text: ' را وارد کنید:'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Visual 6-Digit PIN Boxes
            GestureDetector(
              onTap: () => _focusNode.requestFocus(),
              child: Stack(
                children: [
                  // Hidden TextField for input catching
                  Opacity(
                    opacity: 0,
                    child: TextField(
                      controller: _otpController,
                      focusNode: _focusNode,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9۰-۹٠-٩]')),
                      ],
                      onChanged: (val) {
                        setState(() {});
                        final normalized = _normalizeDigits(val);
                        if (normalized.length == 6 && !_isLoading) {
                          _verifyCode();
                        }
                      },
                    ),
                  ),
                  // Rendered 6 Boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      final digit = index < rawDigits.length ? rawDigits[index] : '';
                      final isFocused = index == rawDigits.length || (index == 5 && rawDigits.length == 6);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 46,
                        height: 56,
                        decoration: BoxDecoration(
                          color: colors.surfaceSunken,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isFocused
                                ? colors.primary
                                : (digit.isNotEmpty ? colors.primary.withValues(alpha: 0.4) : colors.border),
                            width: isFocused ? 2.0 : 1.0,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            digit,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: colors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: colors.error, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Timer & Resend Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_secondsRemaining > 0)
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 18, color: colors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'ارسال مجدد تا ${_formatTime(_secondsRemaining)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                else
                  TextButton.icon(
                    onPressed: _isResending ? null : _resendCode,
                    icon: _isResending
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
                          )
                        : Icon(Icons.refresh_rounded, size: 18, color: colors.primary),
                    label: Text(
                      'ارسال مجدد کد',
                      style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),

                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: (_isLoading || rawDigits.length != 6) ? null : _verifyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: colors.onPrimary),
                          )
                        : const Text('تأیید و ورود', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
