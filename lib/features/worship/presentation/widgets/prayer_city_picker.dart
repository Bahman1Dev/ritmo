import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/services/prayer_time_provider.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/ux/ritmo_snackbar.dart';
import 'package:ritmo/features/worship/logic/worship_engine.dart';
import 'package:ritmo/features/worship/models/worship_models.dart';
import 'package:sqflite/sqflite.dart';

class PrayerCityPicker extends StatefulWidget {

  const PrayerCityPicker({
    super.key,
    required this.onChanged,
    this.initialTab = 0,
  });
  final VoidCallback onChanged;
  final int initialTab;

  @override
  State<PrayerCityPicker> createState() => _PrayerCityPickerState();
}

class _PrayerCityPickerState extends State<PrayerCityPicker> {
  late int _activeTab;
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _filteredCities = [];
  bool _isLoadingCities = true;

  // Settings State
  String _selectedMethod = 'TEHRAN_GEOPHYSICS';
  String _currentCityId = 'TEHRAN_TEHRAN';
  bool _showAsrIsha = false;
  int _hijriOffset = 0;
  bool _isSavingSettings = false;

  final List<Map<String, String>> _methods = [
    {'key': 'TEHRAN_GEOPHYSICS', 'label': 'مؤسسه ژئوفیزیک دانشگاه تهران'},
    {'key': 'MWL', 'label': 'اتحادیه جهان اسلام (MWL)'},
    {'key': 'ISNA', 'label': 'جامعه اسلامی آمریکای شمالی (ISNA)'},
    {'key': 'MAKKAH', 'label': 'ام‌القری مکه'},
  ];

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    _loadSettingsAndCities();
  }

  Future<void> _loadSettingsAndCities() async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Load Settings
      final settingsList = await db.query('app_settings');
      final settings = {
        for (final row in settingsList) row['key']! as String: row['value']! as String
      };

      _selectedMethod = settings['prayer_calculation_method'] ?? 'TEHRAN_GEOPHYSICS';
      _currentCityId = settings['prayer_city_id'] ?? 'TEHRAN_TEHRAN';
      _showAsrIsha = settings['show_asr_isha_prayers'] == 'true';
      _hijriOffset = int.tryParse(settings['hijri_offset'] ?? '0') ?? 0;

      // Load Cities
      final cityResults = await db.query('iran_cities', orderBy: 'city ASC');
      
      if (mounted) {
        setState(() {
          _cities = cityResults;
          _filteredCities = cityResults;
          _isLoadingCities = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading settings and cities: $e');
      if (mounted) {
        setState(() {
          _isLoadingCities = false;
        });
      }
    }
  }

  /// Normalize Persian/Arabic text for search: maps Persian-specific
  /// characters to their Arabic equivalents and strips diacritics/
  /// zero-width characters so that partial queries like "کب" match "كبودرآهنگ".
  String _normalizePersian(String text) {
    var s = text.toLowerCase();
    // Persian-specific characters → Arabic equivalents
    // ک (U+06A9) → ك (U+0643)
    // ی (U+06CC) → ي (U+064A)
    // ة (U+0629) → ه (U+0647)
    // ٱ (U+0671) → ا (U+0627)
    s = s.replaceAll('\u06A9', '\u0643'); // ک → ك
    s = s.replaceAll('\u06CC', '\u064A'); // ی → ي
    s = s.replaceAll('\u0629', '\u0647'); // ة → ه
    s = s.replaceAll('\u0671', '\u0627'); // ٱ → ا
    // Remove zero-width joiners/non-joiners
    s = s.replaceAll('\u200C', ''); // ZWNJ
    s = s.replaceAll('\u200D', ''); // ZWJ
    // Remove Arabic diacritics (tashkeel)
    s = s.replaceAll(RegExp('[\u0617-\u061A\u064B-\u0652]'), '');
    return s;
  }

  void _filterCities(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredCities = _cities;
      } else {
        final q = _normalizePersian(query);
        _filteredCities = _cities.where((c) {
          final cityName = _normalizePersian(c['city'] as String? ?? '');
          final provinceName = _normalizePersian(c['province'] as String? ?? '');
          return cityName.contains(q) || provinceName.contains(q);
        }).toList();
      }
    });
  }

  Future<void> _selectCity(String cityId) async {
    unawaited(HapticFeedback.mediumImpact());
    try {
      final db = await DatabaseHelper.instance.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      // 1. Update local state immediately
      setState(() {
        _currentCityId = cityId;
      });

      // 2. Update city ID setting
      await db.insert(
        'app_settings',
        {
          'key': 'prayer_city_id',
          'value': cityId,
          'updatedAt': nowMs,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await db.insert(
        'app_settings',
        {
          'key': 'home_city_id',
          'value': cityId,
          'updatedAt': nowMs,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Invalidate engine cache and purge SQLite cache so new city persists instantly
      await db.delete('prayer_times_cache');
      WorshipEngine.instance.invalidate();

      // 3. Re-cache prayer times
      await PrayerTimeProvider.instance.cachePrayerTimes(
        cityId: cityId,
        date: DateTime.now(),
      );

      widget.onChanged();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving selected city: $e');
    }
  }

  Future<void> _saveSettings() async {
    if (_isSavingSettings) return;
    setState(() {
      _isSavingSettings = true;
    });

    unawaited(HapticFeedback.mediumImpact());
    try {
      final db = await DatabaseHelper.instance.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      final batch = db.batch();

      // 1. Update calculation method
      batch.insert(
        'app_settings',
        {
          'key': 'prayer_calculation_method',
          'value': _selectedMethod,
          'updatedAt': nowMs,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Update show_asr_isha_prayers setting
      batch.insert(
        'app_settings',
        {
          'key': 'show_asr_isha_prayers',
          'value': _showAsrIsha ? 'true' : 'false',
          'updatedAt': nowMs,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Update hijri_offset setting
      batch.insert(
        'app_settings',
        {
          'key': 'hijri_offset',
          'value': _hijriOffset.toString(),
          'updatedAt': nowMs,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      batch.delete('prayer_times_cache');
      await batch.commit(noResult: true);

      WorshipEngine.instance.invalidate();

      // 2. Ultra-fast batch caching for 40 days (~10ms)
      await PrayerTimeProvider.instance.cacheRange(
        cityId: _currentCityId,
        from: DateTime.now(),
        days: 40,
      );

      widget.onChanged();
      if (mounted) {
        Navigator.pop(context);
        RitmoSnackbar.success(context, 'تنظیمات اوقات شرعی با موفقیت ذخیره شد 🕌');
      }
    } catch (e) {
      debugPrint('Error saving settings: $e');
      if (mounted) {
        setState(() {
          _isSavingSettings = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RitmoTheme.glassCardLight(
        borderRadius: 28,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'تنظیمات اوقات شرعی',
                    style: TextStyle(
                      fontSize: 17.5,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                  IconButton(
                    icon: Icon(CupertinoIcons.xmark, color: colors.textSecondary, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Segmented Tab bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xff0b0b0e) : colors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: isDark ? Border.all(color: const Color(0xffD4A843).withValues(alpha: 0.15), width: 1.2) : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _activeTab = 0;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _activeTab == 0
                                ? (isDark ? Colors.white.withValues(alpha: 0.1) : colors.bg)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              '📍 انتخاب شهر',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _activeTab = 1;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _activeTab == 1
                                ? (isDark ? Colors.white.withValues(alpha: 0.1) : colors.bg)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              '⚙️ تنظیمات محاسبه',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Content Area
              Expanded(
                child: _activeTab == 0 ? _buildCityTab(colors) : _buildSettingsTab(colors),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCityTab(RitmoColors colors) {
    if (_isLoadingCities) {
      return Center(
        child: CircularProgressIndicator(color: colors.textPrimary),
      );
    }

    return Column(
      children: [
        // Search TextField
        TextField(
          onChanged: _filterCities,
          style: TextStyle(color: colors.textPrimary, fontSize: 14.5, fontFamily: 'Vazirmatn'),
          decoration: InputDecoration(
            hintText: 'جستجوی نام شهر یا استان...',
            hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.5), fontSize: 13.5),
            prefixIcon: Icon(CupertinoIcons.search, color: colors.textSecondary, size: 20),
            fillColor: colors.textSecondary.withValues(alpha: 0.02),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colors.textSecondary.withValues(alpha: 0.06)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colors.primary.withValues(alpha: 0.4)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // List of Cities
        Expanded(
          child: _filteredCities.isEmpty
              ? Center(
                  child: Text(
                    'هیچ شهری یافت نشد.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 14.5, fontFamily: 'Vazirmatn'),
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredCities.length,
                  itemBuilder: (context, index) {
                    final cityData = _filteredCities[index];
                    final cityId = cityData['id'] as String;
                    final cityName = cityData['city'] as String;
                    final provinceName = cityData['province'] as String;
                    final isSelected = cityId == _currentCityId;

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xffD4A843).withValues(alpha: 0.1)
                            : colors.textSecondary.withValues(alpha: 0.01),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xffD4A843).withValues(alpha: 0.4)
                              : colors.textSecondary.withValues(alpha: 0.04),
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        title: Text(
                          cityName,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        subtitle: Text(
                          provinceName,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12.5,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(CupertinoIcons.checkmark_alt, color: Color(0xffD4A843), size: 18)
                            : Icon(CupertinoIcons.location, color: colors.textSecondary.withValues(alpha: 0.4), size: 16),
                        onTap: () => _selectCity(cityId),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSettingsTab(RitmoColors colors) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Calculation Method Section
          Text(
            'روش محاسبه اوقات شرعی',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
              fontFamily: 'Vazirmatn',
            ),
          ),
          const SizedBox(height: 8),
          ..._methods.map((method) {
            final isSelected = _selectedMethod == method['key'];

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedMethod = method['key']!;
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xffD4A843).withValues(alpha: 0.08)
                      : colors.textSecondary.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xffD4A843).withValues(alpha: 0.4)
                        : colors.textSecondary.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        method['label']!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected 
                              ? (isDark ? Colors.white : const Color(0xffB48A23)) 
                              : colors.textPrimary,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(CupertinoIcons.checkmark_alt, color: Color(0xffD4A843), size: 18),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),

          const SizedBox(height: 16),

          // Online API Refresh Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffD4A843),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            ),
            icon: const Icon(CupertinoIcons.cloud_download, size: 20),
            label: const Text(
              'به‌روزرسانی آنلاین اوقات شرعی از API',
              style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn', fontSize: 14),
            ),
            onPressed: () async {
              unawaited(HapticFeedback.mediumImpact());
              try {
                final db = await DatabaseHelper.instance.database;
                await db.delete('prayer_times_cache');
                WorshipEngine.instance.invalidate();

                await PrayerTimeProvider.instance.cacheRange(
                  cityId: _currentCityId,
                  from: DateTime.now(),
                  days: 30,
                  forceOnline: true,
                );

                widget.onChanged();
                if (mounted) {
                  RitmoSnackbar.success(context, 'اوقات شرعی از API آنلاین به‌روزرسانی شد 🕌');
                }
              } catch (e) {
                if (mounted) {
                  RitmoSnackbar.error(context, 'بروزرسانی از API ناموفق بود؛ محاسبه آفلاین فعال است.');
                }
              }
            },
          ),
          const SizedBox(height: 20),

          // Show Asr and Isha Switch Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'نمایش زمان عصر و عشا',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              Switch(
                value: _showAsrIsha,
                activeThumbColor: const Color(0xffD4A843),
                onChanged: (val) {
                  setState(() {
                    _showAsrIsha = val;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Hijri Offset Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تصحیح تاریخ هلال ماه (قمری)',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              Text(
                _hijriOffset == 0
                    ? 'بدون تغییر'
                    : toPersianDigits('${_hijriOffset > 0 ? "+" : ""}$_hijriOffset روز'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xffD4A843),
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xffD4A843),
              inactiveTrackColor: Colors.white12,
              thumbColor: const Color(0xffD4A843),
              overlayColor: const Color(0xffD4A843).withValues(alpha: 0.2),
              valueIndicatorColor: const Color(0xffD4A843),
              valueIndicatorTextStyle: TextStyle(fontFamily: 'Vazirmatn', color: colors.textPrimary),
            ),
            child: Slider(
              value: _hijriOffset.toDouble(),
              min: -2,
              max: 2,
              divisions: 4,
              label: toPersianDigits('${_hijriOffset > 0 ? "+" : ""}$_hijriOffset'),
              onChanged: (val) {
                setState(() {
                  _hijriOffset = val.round();
                });
              },
            ),
          ),
          const SizedBox(height: 30),

          // Save button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffD4A843),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _isSavingSettings ? null : _saveSettings,
            child: _isSavingSettings
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CupertinoActivityIndicator(color: Colors.white),
                  )
                : const Text(
                    'ذخیره تنظیمات محاسبه',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
