import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';

import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/supplementary_sports/data/models/ss_user_profile_model.dart';
import 'package:ritmo/features/supplementary_sports/presentation/ss_onboarding_flow.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/shared/primary_button.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/shared/ss_lottie_player.dart';
import 'package:ritmo/features/supplementary_sports/supplementary_sports_theme.dart';

import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/utils/ritmo_id_factory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class SSSettingsScreen extends StatefulWidget {

  const SSSettingsScreen({super.key, this.isModal = false});
  final bool isModal;

  @override
  State<SSSettingsScreen> createState() => _SSSettingsScreenState();
}

class _SSSettingsScreenState extends State<SSSettingsScreen> {
  bool _isLoading = true;
  SsUserProfile? _profile;

  // Settings
  bool _remindersEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 18, minute: 0);
  bool _morningCheckinEnabled = true;
  
  bool _ttsEnabled = true;
  bool _ttsCountdownEnabled = true;
  bool _audioCuesEnabled = true;
  int _defaultRestSeconds = 90;
  bool _unitsMetric = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final profiles = await db.query('ss_user_profile', where: 'id = ?', whereArgs: ['default']);
      
      final prefs = await SharedPreferences.getInstance();
      
      final remindEnabled = prefs.getBool('ss_reminders_enabled') ?? false;
      final remindHour = prefs.getInt('ss_reminders_hour') ?? 18;
      final remindMinute = prefs.getInt('ss_reminders_minute') ?? 0;
      final morningCheck = prefs.getBool('ss_morning_checkin_enabled') ?? true;

      final tts = prefs.getBool('ss_tts_enabled') ?? true;
      final ttsCountdown = prefs.getBool('ss_tts_countdown_enabled') ?? true;
      final cues = prefs.getBool('ss_audio_cues_enabled') ?? true;
      final rest = prefs.getInt('ss_default_rest_seconds') ?? 90;
      final metric = prefs.getBool('ss_units_metric') ?? true;

      setState(() {
        if (profiles.isNotEmpty) {
          _profile = SsUserProfile.fromMap(profiles.first);
        }
        _remindersEnabled = remindEnabled;
        _reminderTime = TimeOfDay(hour: remindHour, minute: remindMinute);
        _morningCheckinEnabled = morningCheck;
        _ttsEnabled = tts;
        _ttsCountdownEnabled = ttsCountdown;
        _audioCuesEnabled = cues;
        _defaultRestSeconds = rest;
        _unitsMetric = metric;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateMainRoutineSchedule(bool enabled, TimeOfDay time) async {
    try {
      const routineId = 'routine_supplementary_sports';
      final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      final now = DateTime.now().millisecondsSinceEpoch;

      final db = await DatabaseHelper.instance.database;
      final check = await db.query('routines', where: 'id = ?', whereArgs: [routineId]);
      final exists = check.isNotEmpty;

      final routineData = {
        'id': routineId,
        'title': 'ورزش تکمیلی',
        'description': 'تمرینات ورزشی هوشمند',
        'category': 'fitness',
        'routineType': 'timeBased',
        'notificationLevel': 'normal',
        'isEssential': 0,
        'targetDurationMinutes': 30,
        'isArchived': enabled ? 0 : 1,
        'displayOrder': 1,
        'createdAt': exists ? check.first['createdAt'] ?? now : now,
        'updatedAt': now,
        'itemType': 'ROUTINE',
        'reminderOffsetMinutes': 15,
      };

      final scheduleData = {
        'id': RitmoIdFactory.schedule(routineId),
        'routineId': routineId,
        'scheduleType': 'RECURRENCE',
        'timeOfDay': timeStr,
        'daysOfWeek': '6,7,1,2,3,4,5',
        'createdAt': exists ? check.first['createdAt'] ?? now : now,
        'updatedAt': now,
      };

      if (exists) {
        await RitmoExecutionKernel.instance.execute(
          EditRoutineCommand(
            routineId: routineId,
            routineData: routineData,
            scheduleData: enabled ? scheduleData : null,
            applyToAll: true,
          ),
        );
      } else if (enabled) {
        await RitmoExecutionKernel.instance.execute(
          CreateRoutineCommand(
            routineData: routineData,
            scheduleData: scheduleData,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating main routine schedule: $e');
    }
  }

  Future<void> _toggleReminders(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ss_reminders_enabled', value);
    setState(() {
      _remindersEnabled = value;
    });

    await _updateMainRoutineSchedule(value, _reminderTime);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? 'یادآور روزانه در سیستم هوشمند ریتمو فعال شد.' : 'یادآور روزانه لغو شد.',
            style: const TextStyle(fontFamily: 'Vazirmatn'),
          ),
        ),
      );
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null && picked != _reminderTime) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('ss_reminders_hour', picked.hour);
      await prefs.setInt('ss_reminders_minute', picked.minute);
      
      setState(() {
        _reminderTime = picked;
      });

      await _updateMainRoutineSchedule(_remindersEnabled, picked);
    }
  }

  Future<void> _toggleMorningCheckin(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ss_morning_checkin_enabled', value);
    setState(() {
      _morningCheckinEnabled = value;
    });
  }

  Future<void> _toggleTts(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ss_tts_enabled', value);
    setState(() {
      _ttsEnabled = value;
    });
  }

  Future<void> _toggleTtsCountdown(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ss_tts_countdown_enabled', value);
    setState(() {
      _ttsCountdownEnabled = value;
    });
  }

  Future<void> _toggleAudioCues(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ss_audio_cues_enabled', value);
    setState(() {
      _audioCuesEnabled = value;
    });
  }

  Future<void> _updateRestSeconds(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ss_default_rest_seconds', value);
    setState(() {
      _defaultRestSeconds = value;
    });
  }

  Future<void> _toggleUnits(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ss_units_metric', value);
    setState(() {
      _unitsMetric = value;
    });
  }

  Future<void> _toggleNeighborFriendly(bool value) async {
    if (_profile == null) return;
    try {
      final db = await DatabaseHelper.instance.database;
      final updatedProfile = _profile!.copyWith(neighborFriendly: value);
      await db.update(
        'ss_user_profile',
        {'neighborFriendly': value ? 1 : 0},
        where: 'id = ?',
        whereArgs: ['default'],
      );
      setState(() {
        _profile = updatedProfile;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value 
                  ? 'حالت بی‌صدا (آپارتمانی) فعال شد. از این پس تمرینات بدون حرکات پرصدا تولید می‌شوند.' 
                  : 'حالت بی‌صدا غیرفعال شد.',
              style: const TextStyle(fontFamily: 'Vazirmatn'),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling neighbor friendly: $e');
    }
  }

  Future<void> _showResetConfirmationDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'آیا مطمئن هستید؟',
            textDirection: TextDirection.rtl,
            style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'با انجام این کار، تمام اطلاعات تمرینی شما برای همیشه حذف می‌شود و این عملیات غیرقابل بازگشت است.',
            textDirection: TextDirection.rtl,
            style: TextStyle(fontFamily: 'Vazirmatn'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'لغو',
                style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.grey),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'بله، بازنشانی کن',
                style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.red, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _resetModule();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetModule() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;

      try {
        await db.execute('PRAGMA foreign_keys = OFF;');
        await db.delete('ss_user_profile');
        await db.delete('ss_workout_plan');
        await db.delete('ss_workout_exercise_crossref');
        await db.delete('ss_exercise_feeling_log');
        await db.delete('ss_workout_session_log');
        await db.delete('ss_plan_version_history');
        await db.delete('ss_decision_log');
        await db.delete('ss_weight_log');
        await db.delete('routine_schedules', where: 'routineId = ?', whereArgs: ['routine_supplementary_sports']);
      } finally {
        await db.execute('PRAGMA foreign_keys = ON;');
      }

      await db.insert('app_settings', {
        'key': 'module_supplementary_sports_enabled',
        'value': 'false',
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('ss_shown_intro_splash');
      await prefs.remove('ss_onboarding_step');
      await prefs.remove('ss_reminders_enabled');
      await prefs.remove('ss_reminders_hour');
      await prefs.remove('ss_reminders_minute');
      await prefs.remove('ss_morning_checkin_enabled');
      await prefs.remove('ss_tts_enabled');
      await prefs.remove('ss_tts_countdown_enabled');
      await prefs.remove('ss_audio_cues_enabled');
      await prefs.remove('ss_default_rest_seconds');
      await prefs.remove('ss_units_metric');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ماژول با موفقیت بازنشانی شد.', style: TextStyle(fontFamily: 'Vazirmatn')),
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      debugPrint('Error resetting module: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getGoalText(FitnessGoal? goal) {
    if (goal == null) return 'نامشخص';
    switch (goal) {
      case FitnessGoal.muscleGain: return 'عضله‌سازی 💪';
      case FitnessGoal.fatLoss: return 'کاهش چربی 🔥';
      case FitnessGoal.bodyRecomposition: return 'تناسب اندام ⚡';
      case FitnessGoal.strength: return 'افزایش قدرت 🏋';
    }
  }

  String _getLevelText(ExperienceLevel? level) {
    if (level == null) return 'نامشخص';
    switch (level) {
      case ExperienceLevel.beginner: return 'تازه‌کار 🌱';
      case ExperienceLevel.intermediate: return 'متوسط 🏃';
      case ExperienceLevel.advanced: return 'پیشرفته 🏆';
    }
  }

  String _getLocationText(TrainingLocation? loc) {
    if (loc == null) return 'نامشخص';
    switch (loc) {
      case TrainingLocation.home: return 'خانه 🏠';
      case TrainingLocation.gym: return 'باشگاه 🏋';
      case TrainingLocation.outdoor: return 'فضای باز 🌳';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFAFAF8),
        body: Center(child: SSLottiePlayer.loading(size: 100)),
      );
    }

    final timeStr = toPersianDigits(
      '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
    );

    final settingsList = ListView(
      padding: EdgeInsets.symmetric(horizontal: widget.isModal ? 0 : SupplementarySportsTheme.spacing24, vertical: 8),
      children: [
        // Section: Profile
        _buildSectionTitle('پروفایل ورزشی شما'),
        const SizedBox(height: SupplementarySportsTheme.spacing12),
        _buildGlassCard(
          isDark: isDark,
          child: Column(
            children: [
              _buildProfileRow('هدف اصلی ورزشی:', _getGoalText(_profile?.goal)),
              const Divider(),
              _buildProfileRow('سطح تجربه:', _getLevelText(_profile?.experienceLevel)),
              const Divider(),
              _buildProfileRow('محل تمرین:', _getLocationText(_profile?.trainingLocation)),
              const SizedBox(height: SupplementarySportsTheme.spacing16),
              PrimaryButton(
                label: 'ویرایش پروفایل ورزشی',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SSOnboardingFlow()),
                  ).then((_) => _loadSettings());
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: SupplementarySportsTheme.spacing32),

        // Section: Coach Settings
        _buildSectionTitle('صدای مربی و افکت‌ها'),
        const SizedBox(height: SupplementarySportsTheme.spacing12),
        _buildGlassCard(
          isDark: isDark,
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('صدای مربی (TTS)', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.w500)),
                subtitle: Text('اعلام صوتی اسم و جزئیات حرکات به فارسی', style: TextStyle(fontFamily: 'Vazirmatn', color: SupplementarySportsTheme.getTextSecondary(context))),
                value: _ttsEnabled,
                activeThumbColor: const Color(0xFF2E7D5B),
                onChanged: _toggleTts,
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('شمارش معکوس صوتی مربی', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.w500)),
                subtitle: Text('اعلام ثانیه‌های آخر استراحت و حرکت به فارسی', style: TextStyle(fontFamily: 'Vazirmatn', color: SupplementarySportsTheme.getTextSecondary(context))),
                value: _ttsCountdownEnabled,
                activeThumbColor: const Color(0xFF2E7D5B),
                onChanged: _toggleTtsCountdown,
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('افکت‌های صوتی تمرین', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.w500)),
                subtitle: Text('پخش صداهای شروع و پایان مراحل تمرینی', style: TextStyle(fontFamily: 'Vazirmatn', color: SupplementarySportsTheme.getTextSecondary(context))),
                value: _audioCuesEnabled,
                activeThumbColor: const Color(0xFF2E7D5B),
                onChanged: _toggleAudioCues,
              ),
            ],
          ),
        ),
        const SizedBox(height: SupplementarySportsTheme.spacing32),

        // Section: General Preference Settings
        _buildSectionTitle('تنظیمات عمومی تمرین'),
        const SizedBox(height: SupplementarySportsTheme.spacing12),
        _buildGlassCard(
          isDark: isDark,
          child: Column(
            children: [
              ListTile(
                title: const Text('مدت زمان استراحت پیش‌فرض', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.w500)),
                subtitle: const Text('زمان استراحت بین ست‌ها و حرکات', style: TextStyle(fontFamily: 'Vazirmatn')),
                trailing: DropdownButton<int>(
                  value: _defaultRestSeconds,
                  onChanged: (val) => val != null ? _updateRestSeconds(val) : null,
                  items: [30, 45, 60, 75, 90, 120].map((seconds) {
                    return DropdownMenuItem<int>(
                      value: seconds,
                      child: Text(toPersianDigits('$seconds ثانیه'), style: const TextStyle(fontFamily: 'Vazirmatn')),
                    );
                  }).toList(),
                ),
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('حالت بی‌صدا (مناسب آپارتمان) 🔇', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.w500)),
                subtitle: Text('حذف خودکار حرکات کوبشی و پر سر و صدا', style: TextStyle(fontFamily: 'Vazirmatn', color: SupplementarySportsTheme.getTextSecondary(context))),
                value: _profile?.neighborFriendly ?? false,
                activeThumbColor: const Color(0xFF2E7D5B),
                onChanged: _toggleNeighborFriendly,
              ),
              const Divider(),
              ListTile(
                title: const Text('واحد اندازه‌گیری', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.w500)),
                subtitle: const Text('فرمت وزن و قد در برنامه', style: TextStyle(fontFamily: 'Vazirmatn')),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ChoiceChip(
                      label: const Text('متریک (کیلوگرم)', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11)),
                      selected: _unitsMetric,
                      onSelected: (val) => _toggleUnits(true),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('امپریال (پوند)', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11)),
                      selected: !_unitsMetric,
                      onSelected: (val) => _toggleUnits(false),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: SupplementarySportsTheme.spacing32),

        // Section: Notifications Settings
        _buildSectionTitle('یادآوری و پایش هوشمند'),
        const SizedBox(height: SupplementarySportsTheme.spacing12),
        _buildGlassCard(
          isDark: isDark,
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('یادآوری روزانه تمرین', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.w500)),
                subtitle: Text('یادآوری شروع جلسه در زمان مقرر', style: TextStyle(fontFamily: 'Vazirmatn', color: SupplementarySportsTheme.getTextSecondary(context))),
                value: _remindersEnabled,
                activeThumbColor: const Color(0xFF2E7D5B),
                onChanged: _toggleReminders,
              ),
              if (_remindersEnabled) ...[
                const Divider(),
                ListTile(
                  title: const Text('زمان یادآوری روزانه', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.w500)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D5B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      timeStr,
                      style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D5B),
                      ),
                    ),
                  ),
                  onTap: _selectTime,
                ),
              ],
              const Divider(),
              SwitchListTile(
                title: const Text('بررسی آمادگی صبحگاهی 🌅', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.w500)),
                subtitle: Text('سوال درباره سطح انرژی و خواب برای تنظیم تمرین روز', style: TextStyle(fontFamily: 'Vazirmatn', color: SupplementarySportsTheme.getTextSecondary(context))),
                value: _morningCheckinEnabled,
                activeThumbColor: const Color(0xFF2E7D5B),
                onChanged: _toggleMorningCheckin,
              ),
            ],
          ),
        ),
        const SizedBox(height: SupplementarySportsTheme.spacing32),

        // Section: Danger Zone / Reset
        _buildSectionTitle('مدیریت داده‌ها و بازنشانی'),
        const SizedBox(height: SupplementarySportsTheme.spacing12),
        _buildGlassCard(
          isDark: isDark,
          child: Column(
            children: [
              ListTile(
                title: const Text(
                  'تنظیم مجدد کامل پروفایل و برنامه ⚠️',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                subtitle: Text(
                  'حذف برنامه فعلی و شروع مجدد آنبوردینگ',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    color: SupplementarySportsTheme.getTextSecondary(context),
                  ),
                ),
                trailing: const Icon(Icons.restore_rounded, color: Colors.redAccent),
                onTap: _showResetConfirmationDialog,
              ),
            ],
          ),
        ),
        const SizedBox(height: SupplementarySportsTheme.spacing24),
      ],
    );

    if (widget.isModal) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: RitmoGlassCardLight(
          borderRadius: 28,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            padding: EdgeInsets.fromLTRB(16, 20, 16, MediaQuery.of(context).viewInsets.bottom + 16),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(CupertinoIcons.gear_alt_fill, color: Color(0xFF2E7D5B), size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'تنظیمات ورزش تکمیلی',
                          style: TextStyle(
                            fontSize: 17.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF133B26),
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(CupertinoIcons.xmark, color: isDark ? Colors.white70 : Colors.black54, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Divider(color: isDark ? Colors.white12 : Colors.black12, height: 16),
                Expanded(child: settingsList),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFAFAF8),
      appBar: AppBar(
        title: const Text('تنظیمات ورزش تکمیلی', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(child: settingsList),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: SupplementarySportsTheme.h2.copyWith(
        color: SupplementarySportsTheme.getTextPrimary(context),
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              color: SupplementarySportsTheme.getTextSecondary(context),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontWeight: FontWeight.bold,
              color: SupplementarySportsTheme.getTextPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child, required bool isDark}) {
    return ClipRRect(
      borderRadius: SupplementarySportsTheme.borderRadiusCard,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(SupplementarySportsTheme.spacing16),
          decoration: BoxDecoration(
            color: isDark 
                ? const Color(0xFF1E293B).withValues(alpha: 0.45) 
                : Colors.white.withValues(alpha: 0.55),
            borderRadius: SupplementarySportsTheme.borderRadiusCard,
            border: Border.all(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.12) 
                  : Colors.white.withValues(alpha: 0.6),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
