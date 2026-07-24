import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/ritmo_id_factory.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/shared/primary_button.dart';

/// Bottom sheet allowing users to define a custom exercise.
class SSCustomExerciseSheet extends StatefulWidget {
  const SSCustomExerciseSheet({super.key});

  @override
  State<SSCustomExerciseSheet> createState() => _SSCustomExerciseSheetState();
}

class _SSCustomExerciseSheetState extends State<SSCustomExerciseSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final String _category = 'cat_lower_body';
  bool _isNoisy = false;
  final int _skillRequired = 1;
  bool _isSaving = false;

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final db = await DatabaseHelper.instance.database;
      final exId = RitmoIdFactory.ssCustomExercise();

      await db.insert('ss_exercise', {
        'id': exId,
        'name': _titleController.text.trim(),
        'nameEn': _titleController.text.trim(),
        'category': _category,
        'instructions': _descController.text.trim(),
        'isCustom': 1,
        'noisy': _isNoisy ? 1 : 0,
        'skillRequired': _skillRequired,
      });

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error creating custom exercise: $e');
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff121212) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ایجاد حرکت ورزشی سفارشی 🏋️',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'نام حرکت',
              hintText: 'مثلاً شنا روی صندلی',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'توضیحات و نحوه اجرا',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('پرصدا یا با ضربه سنگین؟ (نامناسب آپارتمان)'),
            value: _isNoisy,
            onChanged: (val) => setState(() => _isNoisy = val),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: _isSaving ? 'در حال ثبت...' : 'ذخیره حرکت سفارشی',
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
    );
  }
}
