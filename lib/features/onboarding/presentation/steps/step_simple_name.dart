import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

class StepSimpleName extends StatelessWidget {
  const StepSimpleName({
    super.key,
    required this.name,
    required this.onNameChanged,
    required this.onStart,
  });

  final String name;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'اسمت چیه؟',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
              fontFamily: 'Vazirmatn',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'می‌تونی خالی بذاری.',
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary,
              fontFamily: 'Vazirmatn',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          TextField(
            autofocus: true,
            controller: TextEditingController(text: name)..selection = TextSelection.collapsed(offset: name.length),
            onChanged: onNameChanged,
            style: TextStyle(
              fontSize: 16,
              color: colors.textPrimary,
              fontFamily: 'Vazirmatn',
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'نام یا نام‌مستعار',
              hintStyle: TextStyle(
                color: colors.textSecondary.withValues(alpha: 0.5),
                fontFamily: 'Vazirmatn',
              ),
              filled: true,
              fillColor: colors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colors.border),
              ),
            ),
          ),
          const SizedBox(height: 28),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: onStart,
            child: const Text(
              'شروع',
              style: TextStyle(
                fontSize: 16,
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
