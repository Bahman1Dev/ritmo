import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/analytics/data_maturity_engine.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/hormonal_intelligence_engine.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/ux/ritmo_directional_icon.dart';
import 'package:shamsi_date/shamsi_date.dart';

class CycleRemindersScreen extends StatefulWidget {
  const CycleRemindersScreen({super.key});

  @override
  State<CycleRemindersScreen> createState() => _CycleRemindersScreenState();
}

class _CycleRemindersScreenState extends State<CycleRemindersScreen> {
  bool _isLoading = true;
  bool _isLocked = true;
  String _enteredPin = '';
  String _pinErrorMessage = '';
  late HormonalEngineOutput _output;
  List<Map<String, dynamic>> _cycleLogs = [];
  Map<String, String> _settings = {};
  String? _firstEnteredPin;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await DatabaseHelper.instance.database;
    final settingsList = await db.query('app_settings');
    _settings = {for (final s in settingsList) s['key']! as String: s['value']! as String};
    
    _output = await HormonalIntelligenceEngine.evaluate(
      db: db,
      appSettings: _settings,
      now: DateTime.now(),
    );

    _cycleLogs = await DatabaseHelper.instance.getCycleLogs();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
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
      final hasPasswordSet = _settings['app_lock_password'] != null && _settings['app_lock_password']!.isNotEmpty;
      
      Future.delayed(const Duration(milliseconds: 250), () async {
        if (!hasPasswordSet) {
          if (_firstEnteredPin == null) {
            // First stage of setting PIN complete
            if (mounted) {
              setState(() {
                _firstEnteredPin = _enteredPin;
                _enteredPin = '';
                _pinErrorMessage = '';
              });
            }
          } else {
            // Second stage: confirm PIN
            if (_enteredPin == _firstEnteredPin) {
              final db = await DatabaseHelper.instance.database;
              final nowMs = DateTime.now().millisecondsSinceEpoch;
              await db.rawInsert(
                'INSERT OR REPLACE INTO app_settings (key, value, updatedAt) VALUES (?, ?, ?)',
                ['app_lock_password', _enteredPin, nowMs],
              );
              
              await HapticFeedback.mediumImpact();
              final settingsList = await db.query('app_settings');
              if (mounted) {
                setState(() {
                  _settings = {for (final s in settingsList) s['key']! as String: s['value']! as String};
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
                  _firstEnteredPin = null; // reset to try setting from scratch
                  _pinErrorMessage = 'رمز عبور با تاییدیه مطابقت ندارد. دوباره تلاش کنید.';
                });
              }
            }
          }
        } else {
          if (_enteredPin == _settings['app_lock_password']) {
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

  void _onFingerprintTapped() {
    HapticFeedback.mediumImpact();
    
    final hasPasswordSet = _settings['app_lock_password'] != null && _settings['app_lock_password']!.isNotEmpty;
    if (!hasPasswordSet) {
      setState(() {
        _pinErrorMessage = 'ابتدا رمز عبور ۴ رقمی خود را تعیین کنید.';
      });
      return;
    }

    if (kIsWeb) {
      setState(() {
        _pinErrorMessage = 'اثر انگشت در این نسخه پشتیبانی نمی‌شود. لطفاً رمز عبور را وارد کنید.';
      });
      return;
    }

    setState(() {
      _isLocked = false;
      _pinErrorMessage = '';
      _enteredPin = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.colors.bg,
        body: const Center(child: CircularProgressIndicator(color: Color(0xffF43F5E))),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.colors;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Gradient (Theme-Aware)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [const Color(0xff0F0E17), const Color(0xff1A1625)]
                      : [const Color(0xffFDF8F7), const Color(0xffF3E8E6)],
                ),
              ),
            ),
          ),

          Positioned.fill(
            child: SafeArea(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  children: [
                    // AppBar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: RitmoIcons.back(context, color: colors.textPrimary),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Text(
                            'یادآوری‌های چرخه بدن',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                          Icon(
                            _isLocked ? CupertinoIcons.lock_fill : CupertinoIcons.lock_open_fill,
                            color: const Color(0xffF43F5E),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Content based on lock state
                    Expanded(
                      child: _isLocked
                          ? _buildLockScreen(colors, isDark)
                          : _buildPrivateContentScreen(colors, isDark),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockScreen(RitmoColors colors, bool isDark) {
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

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Locked card
              RitmoTheme.glassCardLight(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        height: 64,
                        width: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xffF43F5E).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(CupertinoIcons.shield_fill, color: Color(0xffF43F5E), size: 32),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        titleText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitleText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSecondary,
                          fontFamily: 'Vazirmatn',
                          height: 1.5,
                        ),
                      ),
                      if (_pinErrorMessage.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          _pinErrorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // PIN Indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          final isActive = _enteredPin.length > index;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            height: 14,
                            width: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive
                                  ? const Color(0xffF43F5E)
                                  : (isDark ? Colors.white24 : Colors.black12),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),

                      // Fingerprint Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                          elevation: 8,
                          shadowColor: colors.primary.withValues(alpha: 0.3),
                        ),
                        onPressed: _onFingerprintTapped,
                        icon: const Icon(CupertinoIcons.device_phone_portrait, size: 18),
                        label: const Text(
                          'ورود با اثر انگشت',
                          style: TextStyle(fontSize: 13, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'یا ورود با رمز عبور',
                        style: TextStyle(
                          fontSize: 10,
                          color: colors.textSecondary,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // PIN Keypad
              SizedBox(
                width: 260,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ['1', '2', '3'].map((k) => _buildKeyBtn(k, colors)).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ['4', '5', '6'].map((k) => _buildKeyBtn(k, colors)).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ['7', '8', '9'].map((k) => _buildKeyBtn(k, colors)).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 64, height: 64),
                        _buildKeyBtn('0', colors),
                        GestureDetector(
                          onTap: _onBackspaceTapped,
                          child: Container(
                            height: 64,
                            width: 64,
                            decoration: BoxDecoration(
                              color: colors.textPrimary.withValues(alpha: 0.04),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(CupertinoIcons.delete_left, color: colors.textPrimary, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyBtn(String key, RitmoColors colors) {
    return GestureDetector(
      onTap: () => _onPinKeyTapped(key),
      child: Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          color: colors.textPrimary.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            key,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
              fontFamily: 'Vazirmatn',
            ),
          ),
        ),
      ),
    );
  }

  // --- 2. Unlocked Private Dashboard ---
  Widget _buildPrivateContentScreen(RitmoColors colors, bool isDark) {
    final nextCycleDate = _output.nextCycleStartDate;
    final jalali = Jalali.fromDateTime(nextCycleDate);
    final monthName = jalali.formatter.mN;
    final weekdayLabel = jalali.formatter.wN;
    final dateStr = '$weekdayLabel ${jalali.day} $monthName';
    final daysToNext = nextCycleDate.difference(DateTime.now()).inDays;

    final hasEnoughData = DataMaturityEngine.hasEnoughDataForCyclePrediction(_cycleLogs.length);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Next cycle prediction card
          RitmoTheme.glassCardLight(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xffF43F5E).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.calendar, color: Color(0xffF43F5E), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'پیش‌بینی زمان شروع دوره بعدی',
                          style: TextStyle(
                            fontSize: 10,
                            color: colors.textSecondary,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasEnoughData ? dateStr : 'در حال شناخت ریتم شما',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasEnoughData ? 'تقریباً در $daysToNext روز آینده' : 'نیاز به ثبت چرخه‌های بیشتر برای پیش‌بینی',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xffF43F5E),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Private Reminders List
          Text(
            'یادآوری‌های محرمانه',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
              fontFamily: 'Vazirmatn',
            ),
          ),
          const SizedBox(height: 12),
          RitmoTheme.glassCardLight(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: _output.privateReminderQueue.map((rem) {
                  final isT0 = rem.level == 'T0';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isT0 ? const Color(0xffF43F5E) : colors.textPrimary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            rem.level,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isT0 ? Colors.white : colors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            rem.message,
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textPrimary,
                              fontFamily: 'Vazirmatn',
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Cycle trend history
          Text(
            'تحلیل الگوی چرخه بدنی',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
              fontFamily: 'Vazirmatn',
            ),
          ),
          const SizedBox(height: 12),
          RitmoTheme.glassCardLight(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'میانگین طول چرخه: ${_settings['cycle_length_days'] ?? '۲۸'} روز',
                        style: TextStyle(fontSize: 11, color: colors.textPrimary, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'طول دوره خونریزی: ${_settings['period_duration_days'] ?? '۷'} روز',
                        style: TextStyle(fontSize: 11, color: colors.textPrimary, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Text(
                    'تاریخچه‌ی دوره‌های ثبت شده:',
                    style: TextStyle(fontSize: 10, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                  ),
                  const SizedBox(height: 8),
                  if (_cycleLogs.isEmpty) Text(
                          'تاکنون هیچ دوره‌ای ثبت نشده است. اطلاعات چرخه به مرور زمان و با ورود دوره‌ها در اینجا نمایش داده می‌شود.',
                          style: TextStyle(fontSize: 11, color: colors.textSecondary, fontFamily: 'Vazirmatn', height: 1.5),
                        ) else ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _cycleLogs.length,
                          itemBuilder: (context, index) {
                            final log = _cycleLogs[index];
                            final startStr = log['cycleStartDate'] as String;
                            final endStr = (log['cycleEndDate'] as String?) ?? 'درحال انجام';
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'شروع: $startStr',
                                    style: TextStyle(fontSize: 11, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                                  ),
                                  Text(
                                    'پایان: $endStr',
                                    style: TextStyle(fontSize: 11, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Privacy Card
          RitmoTheme.glassCardLight(
            color: Colors.green.withValues(alpha: isDark ? 0.08 : 0.04),
            border: Border.all(color: Colors.green.withValues(alpha: 0.18)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(CupertinoIcons.checkmark_seal_fill, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'حریم خصوصی شما برای ما مهم است',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildPrivacyPoint('اطلاعات فقط روی دستگاه شما ذخیره می‌شود و کاملاً محلی است.', colors),
                  _buildPrivacyPoint('برای هیچ سرور یا سرویس خارجی ارسال نمی‌گردد.', colors),
                  _buildPrivacyPoint('صرفاً جهت بهبود و انطباق تجربه شخصی شما در ریتمو استفاده می‌شود.', colors),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Lock button to lock again manually
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _enteredPin = '';
                  _isLocked = true;
                });
              },
              icon: const Icon(CupertinoIcons.lock_fill, size: 16, color: Color(0xffF43F5E)),
              label: const Text(
                'قفل مجدد اطلاعات خصوصی',
                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: Color(0xffF43F5E), fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyPoint(String text, RitmoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(CupertinoIcons.check_mark, color: Colors.green, size: 12),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 10,
                color: colors.textPrimary.withValues(alpha: 0.8),
                fontFamily: 'Vazirmatn',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
