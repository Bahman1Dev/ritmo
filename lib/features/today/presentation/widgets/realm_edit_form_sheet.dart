import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/realm/active_realm_resolver.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

class RealmTemplate {
  const RealmTemplate({
    required this.name,
    required this.icon,
    required this.colorHex,
    required this.mode,
    required this.startTime,
    required this.endTime,
    required this.daysOfWeek,
  });

  final String name;
  final String icon;
  final String colorHex;
  final RealmMode mode;
  final String startTime;
  final String endTime;
  final Set<int> daysOfWeek;
}

class RealmEditFormSheet extends StatefulWidget {
  const RealmEditFormSheet({
    super.key,
    this.initialRealm,
    this.initialSchedules,
    required this.onSave,
  });

  final RealmData? initialRealm;
  final List<RealmScheduleData>? initialSchedules;
  final Future<void> Function(RealmData realm, List<RealmScheduleData> schedules) onSave;

  static const List<RealmTemplate> readyTemplates = [
    RealmTemplate(
      name: 'کار عمیق',
      icon: '💻',
      colorHex: '#6366F1',
      mode: RealmMode.focus,
      startTime: '09:00',
      endTime: '17:00',
      daysOfWeek: {6, 7, 1, 2, 3, 4}, // Sat to Thu
    ),
    RealmTemplate(
      name: 'خواب و استراحت',
      icon: '🌙',
      colorHex: '#8B5CF6',
      mode: RealmMode.silent,
      startTime: '23:00',
      endTime: '06:00',
      daysOfWeek: {1, 2, 3, 4, 5, 6, 7}, // Every day
    ),
    RealmTemplate(
      name: 'ورزش و تندرستی',
      icon: '🏃‍♂️',
      colorHex: '#10B981',
      mode: RealmMode.normal,
      startTime: '06:00',
      endTime: '07:30',
      daysOfWeek: {1, 2, 3, 4, 5, 6, 7},
    ),
    RealmTemplate(
      name: 'مطالعه و یادگیری',
      icon: '📚',
      colorHex: '#EC4899',
      mode: RealmMode.focus,
      startTime: '18:00',
      endTime: '20:00',
      daysOfWeek: {6, 7, 1, 2, 3, 4},
    ),
  ];

  static const List<String> iconPickerOptions = [
    '🎯', '💻', '📚', '🌙', '🏃‍♂️', '⚡', '☕', '🎧', '🎨', '🧘‍♂️', '⚙️', '💡', '🔥', '🌱', '⭐', '❤️'
  ];

  static const List<String> colorPaletteHex = [
    '#6366F1', '#8B5CF6', '#EC4899', '#10B981', '#F59E0B', '#EF4444', '#3B82F6', '#14B8A6'
  ];

  @override
  State<RealmEditFormSheet> createState() => _RealmEditFormSheetState();
}

class _RealmEditFormSheetState extends State<RealmEditFormSheet> {
  late TextEditingController _nameController;
  late String _selectedIcon;
  late String _selectedColorHex;
  late RealmMode _selectedMode;

  late Set<int> _selectedDays; // 1: Mon ... 7: Sun
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  String? _nameError;
  String? _daysError;
  bool _isSubmitting = false;

  bool get isEditing => widget.initialRealm != null;

  @override
  void initState() {
    super.initState();
    final r = widget.initialRealm;
    final sched = (widget.initialSchedules != null && widget.initialSchedules!.isNotEmpty)
        ? widget.initialSchedules!.first
        : null;

    _nameController = TextEditingController(text: r?.name ?? '');
    _selectedIcon = r?.icon ?? '🎯';
    _selectedColorHex = r?.colorHex ?? '#6366F1';
    _selectedMode = r?.mode ?? RealmMode.focus;

    _selectedDays = sched?.daysOfWeek ?? {6, 7, 1, 2, 3, 4}; // Sat to Thu by default

    _startTime = _parseTimeOfDay(sched?.startTime ?? '09:00');
    _endTime = _parseTimeOfDay(sched?.endTime ?? '17:00');
  }

  TimeOfDay _parseTimeOfDay(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length == 2) {
      return TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 9,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }
    return const TimeOfDay(hour: 9, minute: 0);
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final h = tod.hour.toString().padLeft(2, '0');
    final m = tod.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _applyTemplate(RealmTemplate template) {
    setState(() {
      _nameController.text = template.name;
      _selectedIcon = template.icon;
      _selectedColorHex = template.colorHex;
      _selectedMode = template.mode;
      _startTime = _parseTimeOfDay(template.startTime);
      _endTime = _parseTimeOfDay(template.endTime);
      _selectedDays = Set.from(template.daysOfWeek);

      _nameError = null;
      _daysError = null;
    });
  }

  void _validateAndSave() async {
    final name = _nameController.text.trim();

    setState(() {
      _nameError = name.isEmpty ? 'لطفاً نام قلمرو را وارد کنید' : null;
      _daysError = _selectedDays.isEmpty ? 'لطفاً حداقل یک روز را انتخاب کنید' : null;
    });

    if (_nameError != null || _daysError != null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final realmId = widget.initialRealm?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

      final realm = RealmData(
        id: realmId,
        name: name,
        colorHex: _selectedColorHex,
        icon: _selectedIcon,
        mode: _selectedMode,
        isDefault: widget.initialRealm?.isDefault ?? false,
        createdAt: widget.initialRealm?.createdAt,
      );

      final scheduleId = (widget.initialSchedules != null && widget.initialSchedules!.isNotEmpty)
          ? widget.initialSchedules!.first.id
          : '${realmId}_sched_1';

      final schedule = RealmScheduleData(
        id: scheduleId,
        zoneId: realmId,
        daysOfWeek: _selectedDays,
        startTime: _formatTimeOfDay(_startTime),
        endTime: _formatTimeOfDay(_endTime),
      );

      await widget.onSave(realm, [schedule]);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 16,
          left: 16,
          right: 16,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sheet Drag Handle & Title
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.textPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'ویرایش قلمرو' : 'ساخت قلمرو جدید',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 22),
                    color: colors.textTertiary,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Templates Bar (Visible on creation)
              if (!isEditing) ...[
                Text(
                  'الگوهای آماده:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colors.textSecondary,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: RealmEditFormSheet.readyTemplates.map((template) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ActionChip(
                          avatar: Text(template.icon, style: const TextStyle(fontSize: 14)),
                          label: Text(template.name, style: const TextStyle(fontSize: 12, fontFamily: 'Vazirmatn')),
                          onPressed: () => _applyTemplate(template),
                          backgroundColor: colors.textPrimary.withValues(alpha: 0.05),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Name Field & Icon Picker
              Text(
                'نام و آیکون قلمرو:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  // Selected Icon Container
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.textPrimary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.textPrimary.withValues(alpha: 0.1)),
                    ),
                    child: Text(_selectedIcon, style: const TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      style: TextStyle(fontSize: 14, color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                      decoration: InputDecoration(
                        hintText: 'مثلاً: کار عمیق، مطالعات شبانه...',
                        hintStyle: TextStyle(fontSize: 13, color: colors.textTertiary, fontFamily: 'Vazirmatn'),
                        filled: true,
                        fillColor: colors.textPrimary.withValues(alpha: 0.04),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onChanged: (_) {
                        if (_nameError != null) setState(() => _nameError = null);
                      },
                    ),
                  ),
                ],
              ),

              // Inline Name Validation Error (ق-۱۹)
              if (_nameError != null) ...[
                const SizedBox(height: 4),
                Text(_nameError!, style: const TextStyle(fontSize: 11, color: Colors.redAccent, fontFamily: 'Vazirmatn')),
              ],

              const SizedBox(height: 16),

              // Icon Grid Picker (ق-۲۱)
              Text('انتخاب آیکون:', style: TextStyle(fontSize: 12, color: colors.textSecondary, fontFamily: 'Vazirmatn')),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: RealmEditFormSheet.iconPickerOptions.map((icon) {
                  final isSelected = icon == _selectedIcon;
                  return InkWell(
                    onTap: () => setState(() => _selectedIcon = icon),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.primary.withValues(alpha: 0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected ? Border.all(color: colors.primary, width: 1.5) : null,
                      ),
                      child: Text(icon, style: const TextStyle(fontSize: 20)),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Color Palette Picker (ق-۳)
              Text('رنگ قلمرو:', style: TextStyle(fontSize: 12, color: colors.textSecondary, fontFamily: 'Vazirmatn')),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: RealmEditFormSheet.colorPaletteHex.map((hex) {
                  final color = RealmData(id: '', name: '', colorHex: hex, icon: '', mode: RealmMode.normal).parseColor();
                  final isSelected = hex.toLowerCase() == _selectedColorHex.toLowerCase();

                  return GestureDetector(
                    onTap: () => setState(() => _selectedColorHex = hex),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: colors.textPrimary, width: 2.5) : null,
                      ),
                      child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),

              // Realm Mode Picker with Live Preview (F-2)
              Text('حالت و سطح تمرکز قلمرو:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn')),
              const SizedBox(height: 8),

              SegmentedButton<RealmMode>(
                segments: const [
                  ButtonSegment(value: RealmMode.focus, label: Text('تمرکز عمیق', style: TextStyle(fontSize: 12, fontFamily: 'Vazirmatn'))),
                  ButtonSegment(value: RealmMode.silent, label: Text('بی‌صدا', style: TextStyle(fontSize: 12, fontFamily: 'Vazirmatn'))),
                  ButtonSegment(value: RealmMode.normal, label: Text('عادی', style: TextStyle(fontSize: 12, fontFamily: 'Vazirmatn'))),
                ],
                selected: {_selectedMode},
                onSelectionChanged: (set) {
                  setState(() => _selectedMode = set.first);
                },
              ),

              const SizedBox(height: 6),

              // Mode Live Preview (F-2 & ق-۵ fix)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.textPrimary.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _selectedMode == RealmMode.focus
                      ? '⚡ فقط روتین‌های ضروری (اصلی) اجازه اعلان و نمایش دارند.'
                      : (_selectedMode == RealmMode.silent
                          ? '💊 روتین‌های دارویی همیشه عبور می‌کنند؛ روتین‌های غیرضروری ساکت می‌شوند.'
                          : '☀️ همه روتین‌ها بر اساس برنامه عادی عمل می‌کنند.'),
                  style: TextStyle(fontSize: 11, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
                ),
              ),

              const SizedBox(height: 18),

              // Days Selector with Shortcuts
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('روزهای فعال:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn')),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _selectedDays = {6, 7, 1, 2, 3, 4, 5}),
                        child: const Text('همه روزها', style: TextStyle(fontSize: 11, fontFamily: 'Vazirmatn')),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _selectedDays = {6, 7, 1, 2, 3, 4}),
                        child: const Text('روزهای کاری', style: TextStyle(fontSize: 11, fontFamily: 'Vazirmatn')),
                      ),
                    ],
                  ),
                ],
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDayChip('ش', 6),
                  _buildDayChip('ی', 7),
                  _buildDayChip('د', 1),
                  _buildDayChip('س', 2),
                  _buildDayChip('چ', 3),
                  _buildDayChip('پ', 4),
                  _buildDayChip('ج', 5),
                ],
              ),

              if (_daysError != null) ...[
                const SizedBox(height: 4),
                Text(_daysError!, style: const TextStyle(fontSize: 11, color: Colors.redAccent, fontFamily: 'Vazirmatn')),
              ],

              const SizedBox(height: 18),

              // Time Range Selector
              Text('ساعات فعال‌سازی:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn')),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: _startTime);
                        if (picked != null) setState(() => _startTime = picked);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: colors.textPrimary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.textPrimary.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('شروع:', style: TextStyle(fontSize: 12, color: colors.textSecondary, fontFamily: 'Vazirmatn')),
                            Text(_formatTimeOfDay(_startTime), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn')),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: _endTime);
                        if (picked != null) setState(() => _endTime = picked);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: colors.textPrimary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.textPrimary.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('پایان:', style: TextStyle(fontSize: 12, color: colors.textSecondary, fontFamily: 'Vazirmatn')),
                            Text(_formatTimeOfDay(_endTime), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary, fontFamily: 'Vazirmatn')),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Save Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _validateAndSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          isEditing ? 'ذخیره تغییرات' : 'ایجاد قلمرو',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn'),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayChip(String label, int weekday) {
    final isSelected = _selectedDays.contains(weekday);
    final colors = context.colors;

    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : colors.textPrimary, fontFamily: 'Vazirmatn')),
      selected: isSelected,
      onSelected: (val) {
        setState(() {
          if (val) {
            _selectedDays.add(weekday);
          } else {
            _selectedDays.remove(weekday);
          }
          if (_daysError != null && _selectedDays.isNotEmpty) {
            _daysError = null;
          }
        });
      },
      selectedColor: colors.primary,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: EdgeInsets.zero,
    );
  }
}
