import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/assistant/models/assistant_models.dart';
import 'package:ritmo/features/assistant/presentation/widgets/assistant_action_preview_sheet.dart';

class AssistantBriefingSection extends StatelessWidget {

  const AssistantBriefingSection({
    super.key,
    required this.briefing,
    required this.nextActions,
    required this.onActionComplete,
    this.isTab = false,
  });
  final DailyBriefing briefing;
  final List<NextAction> nextActions;
  final VoidCallback onActionComplete;
  final bool isTab;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final hasNoData = briefing.text.isEmpty && nextActions.isEmpty && briefing.highlights.isEmpty;

    if (hasNoData) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xff06B6D4).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.sparkles, color: Color(0xff06B6D4), size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                'هنوز دارم اپت رو می‌شناسم ✨',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'داده‌های کافی برای سنتز بریفینگ وجود ندارد. با ثبت روتین‌ها، خواب و وضعیت روزانه به من کمک کنید تا شما را بهتر بشناسم.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 12,
                  color: colors.textSecondary,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        isTab ? 130.0 + MediaQuery.of(context).padding.bottom : 12.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Glowing Briefing Card
          if (briefing.text.isNotEmpty) ...[
            Text(
              'خلاصه وضعیت امروز',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xff06B6D4).withValues(alpha: 0.25),
                  width: 1.5,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xff06B6D4).withValues(alpha: 0.12),
                    const Color(0xff8B5CF6).withValues(alpha: 0.08),
                  ],
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          briefing.text,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 13,
                            height: 1.6,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Stats Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildBriefingStat(
                                label: 'روتین‌های امروز',
                                value: '${briefing.stats['todayCompletions'] ?? 0} از ${briefing.stats['totalRoutines'] ?? 0}',
                                icon: CupertinoIcons.repeat,
                                color: const Color(0xff10B981),
                                colors: colors,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildBriefingStat(
                                label: 'اهداف معوقه',
                                value: '${briefing.stats['overdueGoalsCount'] ?? 0} هدف',
                                icon: CupertinoIcons.flag_fill,
                                color: const Color(0xffF59E0B),
                                colors: colors,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // 2. Next Actions Section
          if (nextActions.isNotEmpty) ...[
            Text(
              'بهترین اقدام‌های بعدی',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: nextActions.length,
              itemBuilder: (context, index) {
                final item = nextActions[index];
                return _buildActionCard(context, item, colors);
              },
            ),
            const SizedBox(height: 20),
          ],

          // 3. System Highlights Section
          if (briefing.highlights.isNotEmpty) ...[
            Text(
              'وضعیت ماژول‌ها',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.1,
              ),
              itemCount: briefing.highlights.length,
              itemBuilder: (context, index) {
                final h = briefing.highlights[index];
                return _buildHighlightCard(h, colors);
              },
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildBriefingStat({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required RitmoColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10.5, color: colors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, fontWeight: FontWeight.bold, color: colors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, NextAction item, RitmoColors colors) {
    // Determine category based on type
    var categoryName = 'عمومی';
    var themeColor = const Color(0xff06B6D4); // Default Cyan
    var categoryIcon = CupertinoIcons.sparkles;

    final type = item.action?.type;
    if (type != null) {
      switch (type) {
        case AssistantActionType.createRoutine:
        case AssistantActionType.completeRoutine:
        case AssistantActionType.skipRoutine:
        case AssistantActionType.editRoutine:
        case AssistantActionType.deleteRoutine:
          categoryName = 'روتین';
          themeColor = const Color(0xff10B981); // Emerald
          categoryIcon = CupertinoIcons.repeat;
        case AssistantActionType.createGoal:
        case AssistantActionType.editGoal:
        case AssistantActionType.completeGoalStep:
          categoryName = 'هدف';
          themeColor = const Color(0xffF59E0B); // Amber
          categoryIcon = CupertinoIcons.flag_fill;
        case AssistantActionType.logSleep:
          categoryName = 'خواب';
          themeColor = const Color(0xff8B5CF6); // Purple
          categoryIcon = CupertinoIcons.moon_stars_fill;
        case AssistantActionType.logEnergyMood:
          categoryName = 'انرژی و حال';
          themeColor = const Color(0xffEC4899); // Pink
          categoryIcon = CupertinoIcons.bolt_horizontal_fill;
        case AssistantActionType.addKonkurItem:
          categoryName = 'کنکور';
          themeColor = const Color(0xff3B82F6); // Blue
          categoryIcon = CupertinoIcons.book_fill;
        case AssistantActionType.createCourse:
          categoryName = 'درس';
          themeColor = const Color(0xffEF4444); // Red
          categoryIcon = CupertinoIcons.play_rectangle_fill;
        case AssistantActionType.createWorshipItem:
          categoryName = 'عبادت';
          themeColor = const Color(0xff14B8A6); // Teal
          categoryIcon = CupertinoIcons.moon_fill;
        case AssistantActionType.logReflection:
          categoryName = 'بازتاب';
          themeColor = const Color(0xff84CC16); // Lime
          categoryIcon = CupertinoIcons.text_quote;
        default:
          categoryName = 'سیستم';
          themeColor = const Color(0xff06B6D4); // Cyan
          categoryIcon = CupertinoIcons.sparkles;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: RitmoTheme.glassCardLight(
        borderRadius: 20,
        color: colors.card.withValues(alpha: 0.6),
        border: Border.all(color: themeColor.withValues(alpha: 0.18), width: 1.2),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row with Title and Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: themeColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            categoryIcon,
                            color: themeColor,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: themeColor.withValues(alpha: 0.25), width: 0.8),
                    ),
                    child: Text(
                      categoryName,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.reason,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 11,
                  color: colors.textSecondary,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 12),
              // Apply Button
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  height: 32,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (item.action != null) {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (context) => AssistantActionPreviewSheet(
                            action: item.action!,
                            onSaved: onActionComplete,
                          ),
                        );
                      }
                    },
                    icon: const Icon(CupertinoIcons.checkmark_alt, size: 14, color: Colors.white),
                    label: const Text(
                      'اعمال پیشنهاد',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      shadowColor: themeColor.withValues(alpha: 0.3),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightCard(BriefingItem item, RitmoColors colors) {
    IconData icon;
    Color iconColor;
    String sysName;
    switch (item.system) {
      case 'sleep':
        icon = CupertinoIcons.moon_stars_fill;
        iconColor = const Color(0xff8B5CF6);
        sysName = 'خواب و استراحت';
      case 'goals':
        icon = CupertinoIcons.flag_fill;
        iconColor = const Color(0xffF59E0B);
        sysName = 'اهداف و پروژه‌ها';
      case 'routines':
        icon = CupertinoIcons.repeat;
        iconColor = const Color(0xff10B981);
        sysName = 'روتین‌های روزانه';
      case 'energy':
        icon = CupertinoIcons.bolt_fill;
        iconColor = const Color(0xffEC4899);
        sysName = 'انرژی و شادابی';
      default:
        icon = CupertinoIcons.sparkles;
        iconColor = const Color(0xff06B6D4);
        sysName = 'ماژول سیستم';
    }

    return RitmoTheme.glassCardLight(
      borderRadius: 16,
      color: colors.card.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 15),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sysName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Expanded(
                    child: Text(
                      item.headline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 10,
                        height: 1.45,
                        color: colors.textPrimary,
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
