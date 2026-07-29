// lib/features/routines/presentation/universal_planner_sheet.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/features/courses/presentation/widgets/create_course_sheet.dart';
import 'package:ritmo/features/goals/presentation/widgets/create_goal_sheet.dart';
import 'package:ritmo/features/health/presentation/widgets/medication_form_sheet.dart';
import 'package:ritmo/features/routines/presentation/forms/course_step2_form.dart';
import 'package:ritmo/features/routines/presentation/forms/generic_step2_form.dart';
import 'package:ritmo/features/routines/presentation/forms/goal_step2_form.dart';
import 'package:ritmo/features/routines/presentation/forms/reflection_step2_form.dart';
// Step 2 Subsystem Forms
import 'package:ritmo/features/routines/presentation/forms/sports_step2_form.dart';
// Extracted components & controller
import 'package:ritmo/features/routines/presentation/planner_controller.dart';
import 'package:ritmo/features/routines/presentation/widgets/confetti_widget.dart';
import 'package:ritmo/features/supplementary_sports/movement/presentation/movement_log_sheet.dart';
import 'package:ritmo/features/routines/presentation/widgets/planner_category_grid.dart';
import 'package:ritmo/features/routines/presentation/widgets/planner_header.dart';
import 'package:ritmo/features/routines/presentation/widgets/planner_journey_preview.dart';
import 'package:ritmo/features/routines/presentation/widgets/planner_natural_input.dart';
import 'package:ritmo/features/routines/presentation/widgets/planner_submit_button.dart';
import 'package:ritmo/features/routines/presentation/widgets/planner_summary_card.dart';
import 'package:ritmo/features/supplementary_sports/presentation/ss_home_dashboard_screen.dart';
import 'package:ritmo/features/worship/models/worship_models.dart';
import 'package:ritmo/features/worship/presentation/widgets/mustahab_section.dart';

// --- MAIN UNIVERSAL PLANNER SHEET ---
class UniversalPlannerSheet extends StatefulWidget {

  const UniversalPlannerSheet({
    super.key,
    required this.onSaved,
    this.routineToEdit,
    this.prefilledTime,
  });
  final Map<String, dynamic>? routineToEdit;
  final VoidCallback onSaved;
  final TimeOfDay? prefilledTime;

  static void show(
    BuildContext context, {
    Map<String, dynamic>? routineToEdit,
    required VoidCallback onSaved,
    TimeOfDay? prefilledTime,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UniversalPlannerSheet(
        routineToEdit: routineToEdit,
        onSaved: onSaved,
        prefilledTime: prefilledTime,
      ),
    );
  }

  @override
  State<UniversalPlannerSheet> createState() => _UniversalPlannerSheetState();
}

class _UniversalPlannerSheetState extends State<UniversalPlannerSheet> {
  late PlannerController _controller;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _controller = PlannerController(
      routineToEdit: widget.routineToEdit,
      onSaved: widget.onSaved,
      prefilledTime: widget.prefilledTime,
      onPageChanged: (pageIndex) {
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            pageIndex,
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeInOutCubic,
          );
        }
      },
    );
    _controller.init();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wire up the medical sheet opener here so `context` is always current
    _controller.setMedicalSheetOpener(([prefillData]) {
      MedicationFormSheet.show(
        context,
        prefillData: prefillData ?? _controller.tempMedicationData,
        onFormCompleted: (formData) {
          _controller.title = formData.name;
          _controller.description = formData.dose;
          _controller.tempMedicationData = formData;
          _controller.selectedCategory = Category.medical;
          _controller.itemType = 'REMINDER';
          _controller.updatePage(2);
        },
      );
    });

    _controller.setWorshipSheetOpener(({prefill}) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (sheetCtx) {
          return AddCustomMustahabSheet(
            practice: prefill != null ? WorshipPractice(
              id: '',
              practiceType: 'MUSTAHAB',
              title: prefill['title'] as String? ?? '',
              createdAt: 0,
              updatedAt: 0,
              dailyTarget: prefill['dailyTarget'] as int? ?? 1,
              reminderAnchor: prefill['reminderAnchor'] as String? ?? 'NONE',
              reminderOffsetMinutes: prefill['reminderOffsetMinutes'] as int? ?? 0,
            ) : null,
            onSaved: () {
              widget.onSaved();
              if (mounted) {
                RitmoToast.show(
                  context,
                  'مستحب سفارشی با موفقیت افزوده شد.',
                );
                Navigator.pop(context);
              }
            },
          );
        },
      );
    });

    _controller.setCourseSheetOpener(({initialValues}) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (sheetCtx) {
          return CreateCourseSheet(
            initialValues: initialValues,
            onCourseCreated: () {
              widget.onSaved();
              if (mounted) {
                Navigator.pop(context);
              }
            },
          );
        },
      );
    });

    _controller.setGoalSheetOpener(({templateData}) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (sheetCtx) {
          return CreateGoalSheet(
            activeGoals: const [],
            routines: const [],
            templateData: templateData,
            onSaved: () {
              widget.onSaved();
              if (mounted) {
                Navigator.pop(context);
              }
            },
          );
        },
      );
    });

    _controller.setSportsLogSheetOpener(({durationMinutes}) {
      showMovementLogSheet(
        context,
        presetDurationMinutes: durationMinutes,
        onLogged: () {
          widget.onSaved();
          if (mounted) {
            Navigator.pop(context);
          }
        },
      );
    });

    _controller.setSportsScreenOpener(() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SSHomeDashboardScreen()),
      ).then((_) {
        widget.onSaved();
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    });

    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return PopScope(
          canPop: !_controller.isDirty || _controller.showSuccessAnim,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            
            final discard = await showDialog<bool>(
              context: context,
              builder: (ctx) => Directionality(
                textDirection: TextDirection.rtl,
                child: AlertDialog(
                  backgroundColor: isDark ? const Color(0xFF16192E) : Colors.white,
                  title: Text(
                    'آیا مطمئن هستید؟',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  content: Text(
                    'ایستگاه در حال ویرایش ذخیره نشده است. آیا می‌خواهید تغییرات را دور بیندازید؟',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      color: colors.textSecondary,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('ادامه ویرایش', style: TextStyle(fontFamily: 'Vazirmatn')),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('دور انداختن', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.red)),
                    ),
                  ],
                ),
              ),
            );
            
            if (discard ?? false) {
              if (context.mounted) {
                _controller.title = '';
                Navigator.of(context).pop();
              }
            }
          },
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: Colors.black.withValues(alpha: 0.45),
                alignment: Alignment.bottomCenter,
                child: GestureDetector(
                  onTap: () {}, // Prevent dismissal when tapping inside the sheet
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.92,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F111E).withValues(alpha: 0.94) : Colors.white.withValues(alpha: 0.94),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Material(
                          color: Colors.transparent,
                          child: Stack(
                            children: [
                              Column(
                                children: [
                                  // Header
                                  PlannerHeader(controller: _controller),
                                  const SizedBox(height: 10),
      
                                  // Step Content PageView or Single Edit Form
                                  Expanded(
                                    child: _controller.isEditing
                                        ? SingleChildScrollView(
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                PlannerNaturalInput(controller: _controller),
                                                const SizedBox(height: 24),
                                                const Divider(),
                                                const SizedBox(height: 16),
                                                _buildDynamicSubsystemForm(),
                                                const SizedBox(height: 80), // Extra padding for the floating submit button
                                              ],
                                            ),
                                          )
                                        : PageView(
                                            controller: _pageController,
                                            physics: const NeverScrollableScrollPhysics(),
                                            children: [
                                              // STEP 1: What?
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                                  children: [
                                                    PlannerNaturalInput(controller: _controller),
                                                    const SizedBox(height: 12),
                                                    Expanded(
                                                      child: PlannerCategoryGrid(controller: _controller),
                                                    ),
                                                    const SizedBox(height: 4),
                                                  ],
                                                ),
                                              ),
      
                                              // STEP 2: When?
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                                  children: [
                                                    Expanded(
                                                      child: SingleChildScrollView(
                                                        child: _buildDynamicSubsystemForm(),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 16),
                                                  ],
                                                ),
                                              ),
      
                                              // STEP 3: Preview
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                                  children: [
                                                    Expanded(
                                                      child: SingleChildScrollView(
                                                        child: Column(
                                                          children: [
                                                            PlannerSummaryCard(controller: _controller),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 16),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),

                                  // Fixed Bottom section (Submit button / Continue button)
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(24, 0, 24, 16 + MediaQuery.of(context).padding.bottom),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        if (!_controller.isEditing &&
                                            _controller.selectedCategory != Category.medical &&
                                            _controller.selectedCategory != Category.religious &&
                                            _controller.currentPage > 0) ...[
                                          CollapsibleJourneyPreview(controller: _controller),
                                          const SizedBox(height: 8),
                                        ],
                                        PlannerSubmitButton(controller: _controller),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // Success Confetti overlay
                              if (_controller.showSuccessAnim)
                                Positioned.fill(
                                  child: ColoredBox(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 80,
                                            height: 80,
                                            decoration: const BoxDecoration(
                                              color: Color(0xff10B981),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            _controller.isEditing
                                                ? 'تغییرات ایستگاه با موفقیت ذخیره شد!'
                                                : 'ایستگاه جدید به مسیر زندگی اضافه شد!',
                                            style: const TextStyle(
                                              fontFamily: 'Vazirmatn',
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          const SizedBox(
                                            height: 100,
                                            width: 300,
                                            child: ConfettiWidget(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDynamicSubsystemForm() {
    switch (_controller.selectedCategory) {
      case Category.religious:
        return _buildWorshipSavedPlaceholder();
      case Category.fitness:
        return SportsStep2Form(controller: _controller);
      case Category.medical:
        return _buildMedicalSavedPlaceholder();
      case Category.learning:
        return CourseStep2Form(controller: _controller);
      case Category.custom:
        return GoalStep2Form(controller: _controller);
      case Category.personal:
        if (_controller.itemType == 'REFLECT') {
          return ReflectionStep2Form(controller: _controller);
        }
        return GenericStep2Form(controller: _controller);
      default:
        return GenericStep2Form(controller: _controller);
    }
  }

  Widget _buildMedicalSavedPlaceholder() {
    final colors = context.colors;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 64, color: colors.primary),
            const SizedBox(height: 16),
            Text(
              'دارو با موفقیت ثبت شد',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'می‌توانید پیش‌نمایش را تأیید کنید.',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 13,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorshipSavedPlaceholder() {
    final colors = context.colors;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 64, color: colors.primary),
            const SizedBox(height: 16),
            Text(
              'عبادت با موفقیت ثبت شد',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'می‌توانید پیش‌نمایش را تأیید کنید.',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 13,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CollapsibleJourneyPreview extends StatefulWidget {
  const CollapsibleJourneyPreview({super.key, required this.controller});
  final PlannerController controller;

  @override
  State<CollapsibleJourneyPreview> createState() => _CollapsibleJourneyPreviewState();
}

class _CollapsibleJourneyPreviewState extends State<CollapsibleJourneyPreview> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16192E).withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.01),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.map_outlined, size: 16, color: colors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'پیش‌نمایش مسیر فعالیت‌ها',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: colors.textSecondary.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: PlannerJourneyPreview(
                controller: widget.controller,
                showTitle: false,
              ),
            ),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}
