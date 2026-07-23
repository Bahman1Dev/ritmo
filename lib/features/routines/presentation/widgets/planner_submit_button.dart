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

    // Disabled check: on step 1 with empty clean title, we block going forward
    final isDisabled = controller.currentPage == 0 && controller.title.trim().isEmpty;

    // Loading check
    final isLoading = controller.isSaving;

    // Determine label and icon
    var label = 'ادامه';
    var icon = Icons.arrow_back_rounded; // Points left in RTL (direction of progress)
    
    if (controller.isEditing) {
      label = 'ذخیره تغییرات';
      icon = Icons.check_rounded;
    } else if (controller.currentPage == 2) {
      label = 'افزودن به مسیر';
      icon = Icons.check_rounded;
    }

    final showQuickSave = controller.currentPage == 0 &&
        !controller.isEditing &&
        controller.title.trim().isNotEmpty &&
        (controller.isTimeParsed || controller.prefilledTime != null);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showQuickSave) ...[
            OutlinedButton.icon(
              onPressed: isLoading ? null : () => controller.save(context),
              icon: Icon(Icons.flash_on_rounded, color: colors.goldAccent, size: 18),
              label: Text(
                'ذخیره سریع ⚡',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: colors.goldAccent,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colors.goldAccent, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          GestureDetector(
            onTap: (isDisabled || isLoading)
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    if (controller.isEditing) {
                      controller.save(context);
                    } else if (controller.currentPage < 2) {
                      controller.updatePage(controller.currentPage + 1);
                    } else {
                      controller.save(context);
                    }
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
