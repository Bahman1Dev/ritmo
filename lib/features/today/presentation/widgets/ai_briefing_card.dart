import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/ai/ai_briefing_service.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/core/ux/ritmo_skeleton.dart';
import 'package:ritmo/features/assistant/logic/assistant_action_registry.dart';
import 'package:ritmo/features/assistant/models/assistant_models.dart';

class AiBriefingCard extends StatelessWidget {

  const AiBriefingCard({
    super.key,
    required this.briefing,
    required this.isLoading,
    required this.onRefresh,
  });
  final AiBriefing? briefing;
  final bool isLoading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: RitmoSkeletonCard(height: 180),
      );
    }

    if (briefing == null) {
      return const SizedBox.shrink();
    }

    final b = briefing!;
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: RitmoTheme.glassCardLight(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        '✨',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'تحلیل هوشمند ریتمو',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.cyanAccent.shade100 : const Color(0xff0891B2),
                        ),
                      ),
                    ],
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      RitmoHaptics.tap();
                      onRefresh();
                    }, minimumSize: const Size(0, 0),
                    child: Icon(
                      CupertinoIcons.sparkles,
                      color: isDark ? Colors.white70 : colors.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Headline
              if (b.headline.isNotEmpty) ...[
                Text(
                  b.headline,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : colors.textPrimary,
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 8),
              ],

              // Summary
              if (b.summary.isNotEmpty) ...[
                Text(
                  b.summary,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 13,
                    height: 1.6,
                    color: isDark ? Colors.white70 : colors.textSecondary,
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 12),
              ],

              // Insights List
              if (b.insights.isNotEmpty) ...[
                Divider(color: isDark ? Colors.white12 : colors.border, height: 1),
                const SizedBox(height: 8),
                ...b.insights.map((insight) => _buildInsightRow(context, insight)),
                const SizedBox(height: 8),
              ],

              // Suggestions Action List
              if (b.suggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: b.suggestions.map((suggestion) => _buildSuggestionWidget(context, suggestion)).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightRow(BuildContext context, BriefingInsight insight) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color dotColor = Colors.blue;
    if (insight.tone == 'positive') {
      dotColor = const Color(0xff10B981);
    } else if (insight.tone == 'attention') {
      dotColor = const Color(0xffF59E0B);
    } else {
      dotColor = const Color(0xff3B82F6);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.rtl,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 8),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text(
              insight.text,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 12,
                color: isDark ? Colors.white60 : colors.textSecondary,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionWidget(BuildContext context, BriefingSuggestion suggestion) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasAction = suggestion.actionType != null && suggestion.actionType!.isNotEmpty;

    if (!hasAction) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          suggestion.text,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 12,
            color: isDark ? Colors.white54 : colors.textSecondary,
          ),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
        ),
      );
    }

    final actionType = AssistantActionType.fromString(suggestion.actionType!);

    return GestureDetector(
      onTap: () {
        RitmoHaptics.tap();
        final action = AssistantAction(
          type: actionType,
          title: suggestion.text,
          payload: suggestion.payload ?? {},
        );
        AssistantActionRegistry.executeAction(context, action, () {
          // Action complete callback
          debugPrint('[BRIEFING_CARD] Action executed: ${suggestion.actionType}');
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              if (isDark) Colors.cyan.withValues(alpha: 0.2) else Colors.cyan.withValues(alpha: 0.12),
              if (isDark) Colors.blue.withValues(alpha: 0.1) else Colors.blue.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.cyan.withValues(alpha: 0.3) : Colors.cyan.withValues(alpha: 0.25)),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Icon(
              actionType.icon,
              size: 15,
              color: isDark ? Colors.cyanAccent : const Color(0xff0891B2),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                suggestion.text,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 12,
                  color: isDark ? Colors.white : const Color(0xff0E7490),
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
