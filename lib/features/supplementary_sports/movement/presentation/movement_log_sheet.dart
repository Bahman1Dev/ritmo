// lib/features/sports/movement/presentation/movement_log_sheet.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/analytics/movement_load_calculator.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/utils/ritmo_id_factory.dart';
import 'package:ritmo/features/supplementary_sports/movement/data/movement_repository.dart';
import 'package:ritmo/features/supplementary_sports/movement/domain/movement_event.dart';
import 'package:ritmo/features/supplementary_sports/movement/domain/movement_kind.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';
import 'package:ritmo/features/supplementary_sports/movement/presentation/movement_custom_kind_sheet.dart';

Future<void> showMovementLogSheet(
  BuildContext context, {
  MovementKind? presetKind,
  DateTime? presetDate,
  int? presetDurationMinutes,
  String? presetVenue,
  VoidCallback? onLogged,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => MovementLogSheet(
      presetKind: presetKind,
      presetDate: presetDate,
      presetDurationMinutes: presetDurationMinutes,
      presetVenue: presetVenue,
      onLogged: onLogged,
    ),
  );
}

class MovementLogSheet extends StatefulWidget {
  const MovementLogSheet({
    super.key,
    this.presetKind,
    this.presetDate,
    this.presetDurationMinutes,
    this.presetVenue,
    this.onLogged,
  });

  final MovementKind? presetKind;
  final DateTime? presetDate;
  final int? presetDurationMinutes;
  final String? presetVenue;
  final VoidCallback? onLogged;

  @override
  State<MovementLogSheet> createState() => _MovementLogSheetState();
}

class _MovementLogSheetState extends State<MovementLogSheet> {
  MovementKind? _selectedKind;
  late DateTime _selectedDateTime;
  late int _durationMinutes;
  MovementIntensity _intensity = MovementIntensity.medium;
  String? _feeling = '👍 خوب';
  
  // Dynamic Metric Inputs
  double _distanceKm = 3.0;
  int _laps = 10;
  double _elevationMeters = 100.0;
  int _steps = 4000;

  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();
  final TextEditingController _companionsController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<MovementKind> _recentKinds = [];
  List<MovementKind> _displayKinds = [];
  MovementFamily _selectedFamilyTab = MovementFamily.endurance;
  bool _isLoadingKinds = true;
  bool _isSaving = false;
  double _userWeightKg = 70.0;

  final List<String> _feelings = ['🔥 عالی', '👍 خوب', '😓 خسته', '💪 سخت بود'];

  @override
  void initState() {
    super.initState();
    _selectedKind = widget.presetKind;
    _selectedDateTime = widget.presetDate ?? DateTime.now();
    _durationMinutes = widget.presetDurationMinutes ?? 30;
    if (widget.presetVenue != null) {
      _venueController.text = widget.presetVenue!;
    }

    _loadInitialData();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _venueController.dispose();
    _companionsController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final db = await DatabaseHelper.instance.database;
    final weight = await MovementLoadCalculator.getUserWeightKg(db);
    final recents = await MovementRepository.instance.recentKinds(limit: 6);
    final kinds = await MovementRepository.instance.getKinds(family: _selectedFamilyTab);

    if (mounted) {
      setState(() {
        _userWeightKg = weight;
        _recentKinds = recents;
        _displayKinds = kinds;
        _selectedKind ??= recents.isNotEmpty ? recents.first : (kinds.isNotEmpty ? kinds.first : null);
        _isLoadingKinds = false;
      });
    }
  }

  Future<void> _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      final kinds = await MovementRepository.instance.getKinds(family: _selectedFamilyTab);
      setState(() => _displayKinds = kinds);
    } else {
      final searchResults = await MovementRepository.instance.searchKinds(query);
      setState(() => _displayKinds = searchResults);
    }
  }

  Future<void> _selectFamilyTab(MovementFamily family) async {
    setState(() {
      _selectedFamilyTab = family;
      _isLoadingKinds = true;
    });
    _searchController.clear();
    final kinds = await MovementRepository.instance.getKinds(family: family);
    if (mounted) {
      setState(() {
        _displayKinds = kinds;
        _isLoadingKinds = false;
      });
    }
  }

  Future<void> _openCustomKindSheet() async {
    final created = await showMovementCustomKindSheet(context);
    if (created != null && mounted) {
      setState(() {
        _selectedKind = created;
        _recentKinds.insert(0, created);
      });
    }
  }

  double get _calculatedMet {
    if (_selectedKind == null) return 4.0;
    return MovementLoadCalculator.metFor(
      baseMet: _selectedKind!.baseMet,
      metLow: _selectedKind!.metLow,
      metHigh: _selectedKind!.metHigh,
      intensity: _intensity,
    );
  }

  double get _calculatedMetMinutes {
    return MovementLoadCalculator.metMinutes(
      met: _calculatedMet,
      durationMinutes: _durationMinutes,
    );
  }

  double get _calculatedCalories {
    return MovementLoadCalculator.calories(
      met: _calculatedMet,
      weightKg: _userWeightKg,
      durationMinutes: _durationMinutes,
    );
  }

  Future<void> _saveLog() async {
    if (_selectedKind == null || _isSaving) return;

    setState(() => _isSaving = true);
    final event = MovementEvent(
      id: RitmoIdFactory.movementLog(),
      kindCode: _selectedKind!.code,
      durationMinutes: _durationMinutes,
      intensity: _intensity,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      loggedAt: _selectedDateTime.millisecondsSinceEpoch,
      feeling: _feeling,
      distanceMeters: _selectedKind!.primaryMetric == MovementMetric.distance ? _distanceKm * 1000 : null,
      elevationMeters: _selectedKind!.primaryMetric == MovementMetric.elevation ? _elevationMeters : null,
      laps: _selectedKind!.primaryMetric == MovementMetric.laps ? _laps : null,
      steps: _selectedKind!.primaryMetric == MovementMetric.steps ? _steps : null,
      venue: _venueController.text.trim().isNotEmpty ? _venueController.text.trim() : null,
      companions: _companionsController.text.trim().isNotEmpty ? _companionsController.text.trim() : null,
      sourceModule: 'MOVEMENT',
    );

    try {
      final res = await MovementRepository.instance.logEvent(event);
      HapticFeedback.mediumImpact();

      if (mounted) {
        final isPr = res['isPr'] as bool? ?? false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isPr ? '🎉 رکورد جدید ثبت شد! عهدی که بستی محکم‌تر شد 🔥' : 'فعالیت ورزشی با موفقیت ثبت شد ✨',
              style: const TextStyle(fontFamily: 'Vazirmatn'),
            ),
            backgroundColor: isPr ? const Color(0xFF10B981) : null,
          ),
        );
        widget.onLogged?.call();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ثبت فعالیت: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            // Top Handle
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // Header Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ثبت فعالیت حرکتی',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.xmark_circle_fill),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Main Scrollable Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: 20 + bottomInset,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- STAGE 1: KIND SELECTION ---
                    if (_recentKinds.isNotEmpty) ...[
                      const Text('انواع اخیر:', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _recentKinds.map((k) {
                            final isSelected = _selectedKind?.code == k.code;
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: ChoiceChip(
                                label: Text('${k.emoji} ${k.titleFa}', style: TextStyle(fontFamily: 'Vazirmatn', color: isSelected ? Colors.white : colors.onSurface)),
                                selected: isSelected,
                                selectedColor: colors.primary,
                                onSelected: (val) {
                                  if (val) setState(() => _selectedKind = k);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Search & Custom Button
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            style: TextStyle(fontFamily: 'Vazirmatn', color: colors.onSurface),
                            decoration: InputDecoration(
                              hintText: 'جست‌وجوی نوع ورزش...',
                              prefixIcon: const Icon(CupertinoIcons.search, size: 20),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _openCustomKindSheet,
                          icon: const Icon(CupertinoIcons.add, size: 18),
                          label: const Text('نوع دلخواه', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Family Tabs
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: MovementFamily.values.map((f) {
                          final isSelected = f == _selectedFamilyTab;
                          return Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: ChoiceChip(
                              label: Text('${f.emoji} ${f.titleFa}', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: isSelected ? Colors.white : colors.onSurface)),
                              selected: isSelected,
                              selectedColor: colors.primary,
                              onSelected: (_) => _selectFamilyTab(f),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Display Kinds Grid/List
                    _isLoadingKinds
                        ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CupertinoActivityIndicator()))
                        : (_displayKinds.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'ورزشی در این دسته یافت نشد. می‌توانید با «نوع دلخواه» اضافه کنید.',
                                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: colors.onSurfaceVariant),
                                ),
                              )
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _displayKinds.map((k) {
                                  final isSelected = _selectedKind?.code == k.code;
                                  return InkWell(
                                    onTap: () => setState(() => _selectedKind = k),
                                    borderRadius: BorderRadius.circular(12),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? CalendarTokens.emerald.withValues(alpha: 0.22)
                                            : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.30),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? CalendarTokens.emerald
                                              : colors.outlineVariant.withValues(alpha: 0.20),
                                          width: isSelected ? 1.5 : 1.0,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(k.emoji, style: const TextStyle(fontSize: 14)),
                                          const SizedBox(width: 6),
                                          Text(
                                            k.titleFa,
                                            style: TextStyle(
                                              fontFamily: 'Vazirmatn',
                                              fontSize: 13,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                              color: isSelected ? CalendarTokens.emerald : colors.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              )),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // --- STAGE 2: DYNAMIC METRICS ---
                    if (_selectedKind != null) ...[
                      Text(
                        'ثبت جزئیات: ${_selectedKind!.emoji} ${_selectedKind!.titleFa}',
                        style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 15, color: colors.primary),
                      ),
                      const SizedBox(height: 16),

                      // Duration Slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('مدت زمان:', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                          Text(
                            '${_durationMinutes.toPersianDigits()} دقیقه',
                            style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, color: colors.primary, fontSize: 16),
                          ),
                        ],
                      ),
                      Slider(
                        value: _durationMinutes.toDouble(),
                        min: 5,
                        max: 180,
                        divisions: 35,
                        activeColor: colors.primary,
                        onChanged: (val) => setState(() => _durationMinutes = val.toInt()),
                      ),
                      const SizedBox(height: 12),

                      // Dynamic Metric Input based on primaryMetric
                      if (_selectedKind!.primaryMetric == MovementMetric.distance) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('مسافت (کیلومتر):', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                            Text('${_distanceKm.toStringAsFixed(1).toPersianDigits()} km', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, color: colors.primary)),
                          ],
                        ),
                        Slider(
                          value: _distanceKm,
                          min: 0.5,
                          max: 50.0,
                          divisions: 99,
                          activeColor: colors.primary,
                          onChanged: (val) => setState(() => _distanceKm = val),
                        ),
                        if (_distanceKm > 0 && _durationMinutes > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'سرعت متوسط: ${(_durationMinutes / _distanceKm).toStringAsFixed(1).toPersianDigits()} min/km',
                              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: colors.onSurfaceVariant),
                            ),
                          ),
                        const SizedBox(height: 12),
                      ] else if (_selectedKind!.primaryMetric == MovementMetric.laps) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('تعداد طول (استخر ۲۵ متری):', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                            Text('${_laps.toPersianDigits()} طول (${(_laps * 25).toPersianDigits()} متر)', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, color: colors.primary)),
                          ],
                        ),
                        Slider(
                          value: _laps.toDouble(),
                          min: 1,
                          max: 100,
                          divisions: 99,
                          activeColor: colors.primary,
                          onChanged: (val) => setState(() => _laps = val.toInt()),
                        ),
                        const SizedBox(height: 12),
                      ] else if (_selectedKind!.primaryMetric == MovementMetric.elevation) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('ارتفاع گرفته‌شده (متر):', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                            Text('${_elevationMeters.toInt().toPersianDigits()} متر', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, color: colors.primary)),
                          ],
                        ),
                        Slider(
                          value: _elevationMeters,
                          min: 10,
                          max: 2000,
                          divisions: 199,
                          activeColor: colors.primary,
                          onChanged: (val) => setState(() => _elevationMeters = val),
                        ),
                        const SizedBox(height: 12),
                      ] else if (_selectedKind!.primaryMetric == MovementMetric.steps) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('تعداد گام:', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                            Text('${_steps.toPersianDigits()} گام', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, color: colors.primary)),
                          ],
                        ),
                        Slider(
                          value: _steps.toDouble(),
                          min: 500,
                          max: 30000,
                          divisions: 59,
                          activeColor: colors.primary,
                          onChanged: (val) => setState(() => _steps = val.toInt()),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],

                    // --- STAGE 3: INTENSITY, FEELING, VENUE ---
                    const Text('شدت تمرین:', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: MovementIntensity.values.map((i) {
                        final isSelected = i == _intensity;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Center(child: Text(i.titleFa, style: TextStyle(fontFamily: 'Vazirmatn', color: isSelected ? Colors.white : colors.onSurface))),
                              selected: isSelected,
                              selectedColor: colors.primary,
                              onSelected: (_) => setState(() => _intensity = i),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    const Text('حالت و احساس تمرین:', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _feelings.map((f) {
                        final isSelected = f == _feeling;
                        return ChoiceChip(
                          label: Text(f, style: TextStyle(fontFamily: 'Vazirmatn', color: isSelected ? Colors.white : colors.onSurface)),
                          selected: isSelected,
                          selectedColor: colors.primary,
                          onSelected: (_) => setState(() => _feeling = f),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    if (_selectedKind != null && _selectedKind!.needsVenue) ...[
                      TextFormField(
                        controller: _venueController,
                        style: TextStyle(fontFamily: 'Vazirmatn', color: colors.onSurface),
                        decoration: InputDecoration(
                          labelText: 'نام مکان / سالن (مثلاً: استخر آزادی)',
                          prefixIcon: const Icon(CupertinoIcons.location_solid, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_selectedKind != null && _selectedKind!.isSocial) ...[
                      TextFormField(
                        controller: _companionsController,
                        style: TextStyle(fontFamily: 'Vazirmatn', color: colors.onSurface),
                        decoration: InputDecoration(
                          labelText: 'همراهان (مثلاً: علی، رضا)',
                          prefixIcon: const Icon(CupertinoIcons.person_2_fill, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    TextFormField(
                      controller: _noteController,
                      style: TextStyle(fontFamily: 'Vazirmatn', color: colors.onSurface),
                      decoration: InputDecoration(
                        labelText: 'یادداشت تمرین (اختیاری)',
                        prefixIcon: const Icon(CupertinoIcons.doc_text, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // --- 🔑 LIVE BOTTOM BAR & SAVE BUTTON ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E2630)
                    : Theme.of(context).colorScheme.surfaceContainerHigh,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Live Stat Preview Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        '≈ ${_calculatedCalories.round().toPersianDigits()} کالری',
                        style: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontWeight: FontWeight.bold,
                          color: CalendarTokens.emerald,
                          fontSize: 13,
                        ),
                      ),
                      Text('·', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      Text(
                        '${_calculatedMetMinutes.round().toPersianDigits()} MET-min',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 13,
                        ),
                      ),
                      Text('·', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      Text(
                        '${((_calculatedMetMinutes / 500.0) * 100).round().toPersianDigits()}٪ بودجه هفته',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade400,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (_selectedKind == null || _isSaving)
                            ? Theme.of(context).disabledColor.withValues(alpha: 0.15)
                            : CalendarTokens.emerald,
                        disabledBackgroundColor: Theme.of(context).disabledColor.withValues(alpha: 0.15),
                        foregroundColor: Colors.white,
                        elevation: _selectedKind == null ? 0 : 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: (_selectedKind == null || _isSaving) ? null : _saveLog,
                      child: _isSaving
                          ? const CupertinoActivityIndicator(color: Colors.white)
                          : const Text(
                              'ثبت و ذخیره فعالیت',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
