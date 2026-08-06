import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_colors.dart';
import 'package:ritmo/features/worship/presentation/widgets/prayer_city_picker.dart';

class TravellerSheet extends StatefulWidget {
  const TravellerSheet({
    super.key,
    required this.isTraveller,
    required this.onSave,
  });

  final bool isTraveller;
  final Function({required bool isTraveller, required int days, String? cityId}) onSave;

  static void show(
    BuildContext context, {
    required bool isTraveller,
    required Function({required bool isTraveller, required int days, String? cityId}) onSave,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TravellerSheet(
        isTraveller: isTraveller,
        onSave: onSave,
      ),
    );
  }

  @override
  State<TravellerSheet> createState() => _TravellerSheetState();
}

class _TravellerSheetState extends State<TravellerSheet> {
  int _selectedDays = 1; // 1 = Today, 3 = 3 days, -1 = Manual
  String? _selectedCityId;
  String? _selectedCityName;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.flight_takeoff_rounded, color: colors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'تنظیمات حالت سفر (نماز قصر)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: colors.border),
              const SizedBox(height: 16),

              Text(
                'مدت زمان سفر:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildOptionChip('فقط امروز', 1),
                  const SizedBox(width: 8),
                  _buildOptionChip('۳ روز', 3),
                  const SizedBox(width: 8),
                  _buildOptionChip('تا لغو دستی', -1),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                'شهر مقصد (اختیاری):',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => PrayerCityPicker(
                      onCitySelected: (cityId) {
                        setState(() {
                          _selectedCityId = cityId;
                          _selectedCityName = cityId;
                        });
                      },
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: colors.elevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedCityName ?? 'انتخاب شهر مقصد...',
                        style: TextStyle(fontSize: 13, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                      ),
                      Icon(Icons.location_city_rounded, size: 18, color: colors.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  if (widget.isTraveller)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          widget.onSave(isTraveller: false, days: 0, cityId: null);
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.error,
                          side: BorderSide(color: colors.error),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('پایان سفر', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (widget.isTraveller) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onSave(isTraveller: true, days: _selectedDays, cityId: _selectedCityId);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('فعال‌سازی سفر', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionChip(String label, int days) {
    final colors = context.colors;
    final isSelected = _selectedDays == days;

    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontFamily: 'Vazirmatn', color: isSelected ? colors.onPrimary : colors.textPrimary)),
      selected: isSelected,
      selectedColor: colors.primary,
      backgroundColor: colors.elevated,
      onSelected: (_) => setState(() => _selectedDays = days),
    );
  }
}
