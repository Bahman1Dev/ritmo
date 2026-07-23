import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/ux/ritmo_pressable.dart';
import 'package:ritmo/features/today/presentation/widgets/dashboard/dashboard_module_summary.dart';

class ModuleSummaryGrid extends StatelessWidget {
  const ModuleSummaryGrid({super.key, required this.summaries, required this.onModuleTap});
  final List<DashboardModuleSummary> summaries;
  final void Function(String moduleId) onModuleTap;

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'سیستم‌های فعال',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
            fontFamily: 'Vazirmatn',
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: summaries.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.75, // ارتفاع کمتر
          ),
          itemBuilder: (context, i) => _ModuleSummaryCard(
            summary: summaries[i],
            onTap: () => onModuleTap(summaries[i].moduleId),
            isDark: isDark,
            colors: colors,
          ),
        ),
      ],
    );
  }
}

class _ModuleSummaryCard extends StatelessWidget {

  const _ModuleSummaryCard({
    required this.summary,
    required this.onTap,
    required this.isDark,
    required this.colors,
  });
  final DashboardModuleSummary summary;
  final VoidCallback onTap;
  final bool isDark;
  final RitmoColors colors;

  @override
  Widget build(BuildContext context) {
    if (summary.backgroundImage != null) {
      return _ImageCard(
        summary: summary,
        onTap: onTap,
        isDark: isDark,
        colors: colors,
      );
    }
    return _PlainCard(
      summary: summary,
      onTap: onTap,
      isDark: isDark,
      colors: colors,
    );
  }
}

// ─── کارت با تصویر پس‌زمینه ────────────────────────────────────────────────
class _ImageCard extends StatelessWidget {

  const _ImageCard({
    required this.summary,
    required this.onTap,
    required this.isDark,
    required this.colors,
  });
  final DashboardModuleSummary summary;
  final VoidCallback onTap;
  final bool isDark;
  final RitmoColors colors;

  @override
  Widget build(BuildContext context) {
    return RitmoPressable(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── تصویر پس‌زمینه ──
            Image.asset(
              summary.backgroundImage!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      summary.accentColor.withValues(alpha: 0.3),
                      summary.accentColor.withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
            ),

            // ── پوشش گرادیان کلی ──
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.45, 1.0],
                  colors: [
                    Colors.black.withValues(alpha: isDark ? 0.20 : 0.08),
                    Colors.transparent,
                    Colors.black.withValues(alpha: isDark ? 0.40 : 0.25),
                  ],
                ),
              ),
            ),

            // ── آیکون و عنوان بالا ──
            Positioned(
              top: 9,
              right: 11,
              left: 11,
              child: Row(
                children: [
                  Container(
                    height: 26,
                    width: 26,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 0.8,
                      ),
                    ),
                    child: Icon(summary.icon, size: 13, color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      summary.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'Vazirmatn',
                        shadows: [
                          Shadow(blurRadius: 4, color: Colors.black45),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── قسمت شیشه‌ای تار در زیر کارت ──
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 52,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.black : Colors.white).withValues(alpha: isDark ? 0.35 : 0.45),
                      border: Border(
                        top: BorderSide(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15),
                          width: 0.8,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          summary.primary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black87,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          summary.secondary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── کارت ساده (بدون تصویر) ─────────────────────────────────────────────────
class _PlainCard extends StatelessWidget {

  const _PlainCard({
    required this.summary,
    required this.onTap,
    required this.isDark,
    required this.colors,
  });
  final DashboardModuleSummary summary;
  final VoidCallback onTap;
  final bool isDark;
  final RitmoColors colors;

  @override
  Widget build(BuildContext context) {
    final accentAlpha = isDark ? 0.18 : 0.10;
    final borderAlpha = isDark ? 0.30 : 0.20;

    return RitmoPressable(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: isDark
                  ? colors.card.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.70),
              border: Border.all(
                color: summary.accentColor.withValues(alpha: borderAlpha),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  summary.accentColor.withValues(alpha: accentAlpha),
                  (isDark ? colors.card : Colors.white).withValues(alpha: 0.40),
                ],
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ردیف آیکون + عنوان
                Row(
                  children: [
                    Container(
                      height: 26, width: 26,
                      decoration: BoxDecoration(
                        color: summary.accentColor.withValues(alpha: isDark ? 0.22 : 0.14),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: summary.accentColor.withValues(alpha: isDark ? 0.40 : 0.30),
                          width: 0.8,
                        ),
                      ),
                      child: Icon(summary.icon, size: 13, color: summary.accentColor),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        summary.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // داده اصلی
                Text(
                  summary.primary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const SizedBox(height: 3),

                // داده فرعی
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: summary.accentColor.withValues(alpha: isDark ? 0.14 : 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    summary.secondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: colors.textSecondary,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
