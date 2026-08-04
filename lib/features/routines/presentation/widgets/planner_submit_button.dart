// lib/features/routines/presentation/widgets/planner_submit_button.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/routines/presentation/planner_controller.dart';

class PlannerSubmitButton extends StatelessWidget {

  const PlannerSubmitButton({super.key, required this.controller});
  final PlannerController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final isDisabled = controller.title.trim().isEmpty;
    final isLoading = controller.isSaving;

    var label = controller.isEditing ? 'ذخیره تغییرات' : 'ثبت ایستگاه ⚡';
    var icon = controller.isEditing ? Icons.check_rounded : Icons.flash_on_rounded;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: (isDisabled || isLoading)
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    controller.save(context);
                  },
            child: Opacity(
              opacity: isDisabled ? 0.4 : 1.0,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: colors.primary,
                  boxShadow: [
                    if (!isDisabled)
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                  ],
                ),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(icon, color: Colors.white, size: 18),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
