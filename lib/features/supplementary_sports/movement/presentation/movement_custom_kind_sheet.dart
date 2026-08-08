// lib/features/sports/movement/presentation/movement_custom_kind_sheet.dart

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/ritmo_id_factory.dart';
import 'package:ritmo/core/utils/text_similarity.dart';
import 'package:ritmo/features/supplementary_sports/movement/data/movement_repository.dart';
import 'package:ritmo/features/supplementary_sports/movement/domain/movement_kind.dart';

Future<MovementKind?> showMovementCustomKindSheet(
  BuildContext context, {
  String? initialTitle,
}) {
  return showModalBottomSheet<MovementKind>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => MovementCustomKindSheet(initialTitle: initialTitle),
  );
}

class MovementCustomKindSheet extends StatefulWidget {
  const MovementCustomKindSheet({super.key, this.initialTitle});
  final String? initialTitle;

  @override
  State<MovementCustomKindSheet> createState() => _MovementCustomKindSheetState();
}

class _MovementCustomKindSheetState extends State<MovementCustomKindSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;

  String _selectedEmoji = '🎯';
  MovementFamily _selectedFamily = MovementFamily.endurance;
  MovementMetric _selectedMetric = MovementMetric.duration;
  double _baseMet = 6.0; // 3.0 (light), 6.0 (medium), 9.0 (high)
  bool _isOutdoor = false;
  bool _isSocial = false;
  bool _needsVenue = false;
  int _jointImpact = 1; // 0: low, 1: medium, 2: high

  bool _isSaving = false;
  MovementKind? _similarFound;

  final List<String> _emojis = [
    '🎯', '🏃', '🚴', '🏊', '⚽', '🏀', '🎾', '🏐',
    '🥊', '🥋', '🧘', '🧗', '🎿', '🏋️', '🚶', '🛼',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _checkSimilarityAndSave() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    if (_similarFound == null) {
      final allKinds = await MovementRepository.instance.getKinds(enabledOnly: false);
      for (final k in allKinds) {
        final sim1 = TextSimilarity.similarity(title, k.titleFa);
        final sim2 = TextSimilarity.similarity(title, k.aliasesFa ?? '');
        if (sim1 >= 0.8 || sim2 >= 0.8) {
          setState(() {
            _similarFound = k;
          });
          return;
        }
      }
    }

    unawaited(_doSave());
  }

  Future<void> _doSave() async {
    setState(() => _isSaving = true);
    final title = _titleController.text.trim();
    final slug = title.replaceAll(RegExp(r'\s+'), '_').toLowerCase();

    final customKind = MovementKind(
      code: RitmoIdFactory.movementCustomKind(slug),
      titleFa: title,
      emoji: _selectedEmoji,
      family: _selectedFamily,
      baseMet: _baseMet,
      metLow: (_baseMet * 0.7).clamp(1.5, 15.0),
      metHigh: (_baseMet * 1.3).clamp(2.0, 18.0),
      primaryMetric: _selectedMetric,
      secondaryMetric: MovementMetric.none,
      isOutdoor: _isOutdoor,
      isSocial: _isSocial,
      needsVenue: _needsVenue,
      jointImpact: _jointImpact,
      isCustom: true,
      isEnabled: true,
      usageCount: 0,
      sortOrder: 100,
    );

    try {
      final created = await MovementRepository.instance.createCustomKind(customKind);
      await HapticFeedback.mediumImpact();
      if (mounted) Navigator.of(context).pop(created);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ثبت نوع جدید: $e')),
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
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: 20 + bottomInset,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'ساخت نوع ورزش سفارشی',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 16),

                if (_similarFound != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'آیا منظورتان "${_similarFound!.emoji} ${_similarFound!.titleFa}" بود؟',
                          style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, color: colors.onSurface),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: colors.primary),
                                onPressed: () => Navigator.of(context).pop(_similarFound),
                                child: const Text('بله، انتخابش کن', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() => _similarFound = null);
                                  _doSave();
                                },
                                child: const Text('نه، جدید بساز', style: TextStyle(fontFamily: 'Vazirmatn')),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Title Input
                TextFormField(
                  controller: _titleController,
                  style: TextStyle(fontFamily: 'Vazirmatn', color: colors.onSurface),
                  decoration: InputDecoration(
                    labelText: 'نام ورزش',
                    hintText: 'مثلاً: پاتیناژ، دارت، تی‌آرایکس...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'لطفاً نام ورزش را وارد کنید' : null,
                ),
                const SizedBox(height: 16),

                // Emoji Picker
                const Text('آیکن / ایموجی:', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _emojis.map((emoji) {
                    final isSelected = emoji == _selectedEmoji;
                    return InkWell(
                      onTap: () => setState(() => _selectedEmoji = emoji),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected ? colors.primary.withValues(alpha: 0.2) : colors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? colors.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Text(emoji, style: const TextStyle(fontSize: 22)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Family Picker
                const Text('خانواده ورزش:', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: MovementFamily.values.map((f) {
                    final isSelected = f == _selectedFamily;
                    return ChoiceChip(
                      label: Text('${f.emoji} ${f.titleFa}', style: TextStyle(fontFamily: 'Vazirmatn', color: isSelected ? Colors.white : colors.onSurface)),
                      selected: isSelected,
                      selectedColor: colors.primary,
                      onSelected: (val) {
                        if (val) setState(() => _selectedFamily = f);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Intensity / MET Level
                const Text('شدت تقریبی فعالیت:', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Column(
                  children: [
                    _buildMetOption(3.0, 'سبک (نفسم بند نمی‌آید)', colors),
                    _buildMetOption(6.0, 'متوسط (نفس‌نفس می‌زنم)', colors),
                    _buildMetOption(9.0, 'شدید (نمی‌توانم صحبت کنم)', colors),
                  ],
                ),
                const SizedBox(height: 16),

                // Primary Metric
                const Text('متریک اصلی اندازهگیری:', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    MovementMetric.duration,
                    MovementMetric.distance,
                    MovementMetric.laps,
                    MovementMetric.elevation,
                    MovementMetric.steps,
                  ].map((m) {
                    final isSelected = m == _selectedMetric;
                    return ChoiceChip(
                      label: Text('${m.code} (${m.unitFa})', style: TextStyle(fontFamily: 'Vazirmatn', color: isSelected ? Colors.white : colors.onSurface)),
                      selected: isSelected,
                      selectedColor: colors.primary,
                      onSelected: (val) {
                        if (val) setState(() => _selectedMetric = m);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Switches
                SwitchListTile(
                  title: const Text('فعالیت در فضای باز است؟', style: TextStyle(fontFamily: 'Vazirmatn')),
                  value: _isOutdoor,
                  onChanged: (v) => setState(() => _isOutdoor = v),
                ),
                SwitchListTile(
                  title: const Text('معمولاً تیمی/گروهی انجام می‌شود؟', style: TextStyle(fontFamily: 'Vazirmatn')),
                  value: _isSocial,
                  onChanged: (v) => setState(() => _isSocial = v),
                ),
                SwitchListTile(
                  title: const Text('نیاز به رزرو سالن/باشگاه دارد؟', style: TextStyle(fontFamily: 'Vazirmatn')),
                  value: _needsVenue,
                  onChanged: (v) => setState(() => _needsVenue = v),
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _isSaving ? null : _checkSimilarityAndSave,
                    child: _isSaving
                        ? const CupertinoActivityIndicator(color: Colors.white)
                        : const Text(
                            'ساخت ورزش سفارشی',
                            style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetOption(double value, String label, RitmoColors colors) {
    final isSelected = _baseMet == value;
    return InkWell(
      onTap: () => setState(() => _baseMet = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary.withValues(alpha: 0.12) : colors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border.withValues(alpha: 0.5),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? colors.primary : colors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? colors.primary : colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
