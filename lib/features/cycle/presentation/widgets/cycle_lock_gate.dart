import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/services/secure_key_store.dart';
import 'package:ritmo/core/settings/settings_service.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:sqflite/sqflite.dart';

class CycleLockGate extends StatefulWidget {
  const CycleLockGate({super.key, required this.child});
  final Widget child;

  @override
  State<CycleLockGate> createState() => _CycleLockGateState();
}

class _CycleLockGateState extends State<CycleLockGate> with WidgetsBindingObserver {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isLoading = true;
  bool _isLocked = true;
  String _enteredPin = '';
  String _pinErrorMessage = '';
  String? _firstEnteredPin;
  Map<String, String> _settings = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettingsAndAuth();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Auto re-lock when app goes to background
      final lockEnabled = _settings['cycle_lock_enabled'] != 'false';
      if (lockEnabled && mounted) {
        setState(() {
          _isLocked = true;
          _enteredPin = '';
          _firstEnteredPin = null;
        });
      }
    }
  }

  Future<void> _loadSettingsAndAuth() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final settingsList = await db.query('app_settings');
      final settingsMap = {for (final s in settingsList) if (s['key'] != null) s['key'].toString(): s['value']?.toString() ?? ''};
      
      final lockEnabled = settingsMap['cycle_lock_enabled'] != 'false';
      
      if (mounted) {
        setState(() {
          _settings = settingsMap;
          _isLoading = false;
          if (!lockEnabled) {
            _isLocked = false;
          }
        });
      }

      if (!lockEnabled) return;

      // If biometric auth is enabled, trigger immediately on load
      final biometricEnabled = settingsMap['cycle_biometric_enabled'] == 'true';
      final hasPasswordSet = settingsMap['app_lock_password'] != null && settingsMap['app_lock_password']!.isNotEmpty;
      if (biometricEnabled && hasPasswordSet && !kIsWeb) {
        // Wait a small delay to let UI build
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _isLocked) {
            _authenticateBiometrics();
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading lock gate settings: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _authenticateBiometrics() async {
    if (kIsWeb) return;
    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      if (!canAuthenticate) {
        setState(() {
          _pinErrorMessage = 'زیست‌سنجی (اثر انگشت/چهره) روی این دستگاه پشتیبانی نمی‌شود.';
        });
        return;
      }
      
      final didAuthenticate = await _auth.authenticate(
        localizedReason: 'لطفاً برای ورود به بخش خصوصی احراز هویت کنید.',
        persistAcrossBackgrounding: true,
      );
      
      if (didAuthenticate) {
        await HapticFeedback.mediumImpact();
        if (mounted) {
          setState(() {
            _isLocked = false;
            _pinErrorMessage = '';
            _enteredPin = '';
          });
        }
      }
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      if (mounted) {
        setState(() {
          _pinErrorMessage = 'خطا در احراز هویت بیومتریک. رمز را وارد کنید.';
        });
      }
    }
  }

  void _onPinKeyTapped(String key) {
    if (_enteredPin.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pinErrorMessage = '';
      _enteredPin += key;
    });

    if (_enteredPin.length == 4) {
      Future.microtask(() async {
        final hasExistingPin = await SecureKeyStore.getKey('cycle_lock_password');
        
        if (hasExistingPin == null || hasExistingPin.isEmpty) {
          if (_firstEnteredPin == null) {
            // First stage PIN complete
            if (mounted) {
              setState(() {
                _firstEnteredPin = _enteredPin;
                _enteredPin = '';
                _pinErrorMessage = '';
              });
            }
          } else {
            // Second stage confirm PIN
            if (_enteredPin == _firstEnteredPin) {
              await SecureKeyStore.setKey('cycle_lock_password', _enteredPin);
              await SettingsService.instance.set('cycle_lock_password', _enteredPin);
              
              await HapticFeedback.mediumImpact();
              if (mounted) {
                setState(() {
                  _isLocked = false;
                  _enteredPin = '';
                  _firstEnteredPin = null;
                });
              }
            } else {
              await HapticFeedback.heavyImpact();
              if (mounted) {
                setState(() {
                  _enteredPin = '';
                  _firstEnteredPin = null;
                  _pinErrorMessage = 'رمز عبور با تاییدیه مطابقت ندارد. دوباره تلاش کنید.';
                });
              }
            }
          }
        } else {
          if (_enteredPin == hasExistingPin) {
            await HapticFeedback.mediumImpact();
            if (mounted) {
              setState(() {
                _isLocked = false;
                _enteredPin = '';
              });
            }
          } else {
            await HapticFeedback.heavyImpact();
            if (mounted) {
              setState(() {
                _enteredPin = '';
                _pinErrorMessage = 'رمز عبور نادرست است. دوباره تلاش کنید.';
              });
            }
          }
        }
      });
    }
  }

  void _onBackspaceTapped() {
    if (_enteredPin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pinErrorMessage = '';
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
    });
  }

  String _toPersianDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var result = input;
    for (var i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], persian[i]);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Material(
        color: Color(0xff08090C),
        child: Center(child: CircularProgressIndicator(color: Color(0xffF43F5E))),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.colors;
    final hasPasswordSet = _settings['app_lock_password'] != null && _settings['app_lock_password']!.isNotEmpty;

    var titleText = 'این بخش خصوصی است';
    var subtitleText = 'برای مشاهده اطلاعات، رمز عبور را وارد کنید.';
    
    if (!hasPasswordSet) {
      if (_firstEnteredPin == null) {
        titleText = 'تعیین رمز عبور جدید';
        subtitleText = 'یک رمز عبور ۴ رقمی جهت محافظت از اطلاعات این بخش تعیین کنید.';
      } else {
        titleText = 'تایید رمز عبور جدید';
        subtitleText = 'لطفاً رمز عبور ۴ رقمی جدید خود را مجدداً وارد کنید تا تایید شود.';
      }
    }

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          IgnorePointer(
            ignoring: _isLocked,
            child: widget.child,
          ),
          if (_isLocked) ...[
            // Blur overlay over the actual cycle screen
            Positioned.fill(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    color: isDark ? Colors.black.withValues(alpha: 0.65) : Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),

            // Passcode Window Dialog (centered glassmorphic card)
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: RitmoTheme.glassCardLight(
                      borderRadius: 32,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        width: 320,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header row inside window
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: Icon(CupertinoIcons.xmark, color: colors.textSecondary, size: 20),
                                  onPressed: () => Navigator.maybePop(context),
                                ),
                                const Text(
                                  'حریم خصوصی چرخه',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                ),
                                const Icon(CupertinoIcons.lock_fill, color: Color(0xffF43F5E), size: 20),
                              ],
                            ),
                            const Divider(height: 24, color: Colors.white10),
                            
                            // Shield Icon
                            Container(
                              height: 52,
                              width: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xffF43F5E).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(CupertinoIcons.shield_fill, color: Color(0xffF43F5E), size: 26),
                            ),
                            const SizedBox(height: 12),
                            
                            // Title
                            Text(
                              titleText,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                            const SizedBox(height: 6),
                            
                            // Subtitle
                            Text(
                              subtitleText,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: colors.textSecondary,
                                fontFamily: 'Vazirmatn',
                                height: 1.4,
                              ),
                            ),
                            if (_pinErrorMessage.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                _pinErrorMessage,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),

                            // PIN dots
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(4, (index) {
                                final isActive = _enteredPin.length > index;
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                  height: 10,
                                  width: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isActive
                                        ? const Color(0xffF43F5E)
                                        : (isDark ? Colors.white24 : Colors.black12),
                                  ),
                                );
                              }),
                            ),
                            
                            if (hasPasswordSet && !kIsWeb) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                ),
                                onPressed: _authenticateBiometrics,
                                icon: const Icon(CupertinoIcons.device_phone_portrait, size: 16),
                                label: const Text(
                                  'تایید هویت بیومتریک',
                                  style: TextStyle(fontSize: 11, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                            
                            const SizedBox(height: 24),
                            
                            // Keypad inside window
                            SizedBox(
                              width: 240,
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: ['1', '2', '3'].map((k) => _buildKeyBtn(k, colors)).toList(),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: ['4', '5', '6'].map((k) => _buildKeyBtn(k, colors)).toList(),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: ['7', '8', '9'].map((k) => _buildKeyBtn(k, colors)).toList(),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const SizedBox(width: 56, height: 56),
                                      _buildKeyBtn('0', colors),
                                      GestureDetector(
                                        onTap: _onBackspaceTapped,
                                        child: Container(
                                          height: 56,
                                          width: 56,
                                          decoration: BoxDecoration(
                                            color: colors.textPrimary.withValues(alpha: 0.04),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(CupertinoIcons.delete_left, color: colors.textPrimary, size: 18),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKeyBtn(String key, RitmoColors colors) {
    return GestureDetector(
      onTap: () => _onPinKeyTapped(key),
      child: Container(
        height: 56,
        width: 56,
        decoration: BoxDecoration(
          color: colors.textPrimary.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            _toPersianDigits(key),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
              fontFamily: 'Vazirmatn',
            ),
          ),
        ),
      ),
    );
  }
}
