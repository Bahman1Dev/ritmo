import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/util/ritmo_number.dart';
import 'package:ritmo/core/utils/ritmo_date_picker.dart';
import 'package:ritmo/features/study/data/study_repository.dart';
import 'package:ritmo/features/study/domain/study_models.dart';
import 'package:uuid/uuid.dart';

class ManualSessionSheet extends StatefulWidget {
  const ManualSessionSheet({super.key, required this.subjects});

  final List<StudySubject> subjects;

  static Future<bool?> show(BuildContext context, {required List<StudySubject> subjects}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ManualSessionSheet(subjects: subjects),
    );
  }

  @override
  State<ManualSessionSheet> createState() => _ManualSessionSheetState();
}

class _ManualSessionSheetState extends State<ManualSessionSheet> {
  late String _selectedSubjectId;
  String? _selectedTopicId;
  int _durationMinutes = 45;
  DateTime _selectedDate = DateTime.now();
  final StudyMode _selectedMode = StudyMode.learn;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedSubjectId = widget.subjects.isNotEmpty ? widget.subjects.first.id : '';
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    if (_selectedSubjectId.isEmpty) return;
    final topics = await StudyRepository.instance.getTopics(subjectId: _selectedSubjectId);
    setState(() {
      _selectedTopicId = topics.isNotEmpty ? topics.first.id : null;
    });
  }

  Future<void> _selectDate() async {
    final picked = await RitmoDatePicker.showJalali(
      context: context,
      initialDate: Jalali.fromDateTime(_selectedDate),
      firstDate: Jalali.fromDateTime(DateTime.now().subtract(const Duration(days: 30))),
      lastDate: Jalali.fromDateTime(DateTime.now()),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked.toDateTime());
    }
  }

  Future<void> _submit() async {
    if (_selectedSubjectId.isEmpty) return;
    final dateIso = _selectedDate.toIso8601String().substring(0, 10);
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final session = StudySession(
      id: const Uuid().v4(),
      subjectId: _selectedSubjectId,
      topicId: _selectedTopicId,
      durationMinutes: _durationMinutes,
      dateIso: dateIso,
      mode: _selectedMode,
      source: 'MANUAL',
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      createdAtMs: nowMs,
    );

    await StudyRepository.instance.recordSession(session);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final jalali = Jalali.fromDateTime(_selectedDate);
    final dateLabel = '${RitmoNumber.faInt(jalali.day)} ${jalali.formatter.mN} ${RitmoNumber.faInt(jalali.year)}';

    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ثبت دستی جلسه مطالعه', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          // Subject Dropdown
          DropdownButtonFormField<String>(
            initialValue: _selectedSubjectId,
            decoration: InputDecoration(
              labelText: 'انتخاب درس',
              labelStyle: TextStyle(fontFamily: 'Vazirmatn', color: colors.textSecondary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            items: widget.subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, style: const TextStyle(fontFamily: 'Vazirmatn')))).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedSubjectId = val);
                _loadTopics();
              }
            },
          ),
          const SizedBox(height: 12),
          // Date Row
          ListTile(
            title: const Text('تاریخ جلسه', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: Text(dateLabel, style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: colors.primary)),
            trailing: TextButton.icon(
              onPressed: _selectDate,
              icon: const Icon(Icons.calendar_today_rounded, size: 16),
              label: const Text('تغییر تاریخ', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12)),
            ),
          ),
          const SizedBox(height: 12),
          // Duration Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('مدت مطالعه (دقیقه)', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, fontWeight: FontWeight.bold)),
              Text('${RitmoNumber.faInt(_durationMinutes)} دقیقه', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 15, fontWeight: FontWeight.bold, color: colors.primary)),
            ],
          ),
          Slider(
            value: _durationMinutes.toDouble(),
            min: 10, max: 240, divisions: 23,
            activeColor: colors.primary,
            onChanged: (v) => setState(() => _durationMinutes = v.toInt()),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('ثبت جلسه', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
