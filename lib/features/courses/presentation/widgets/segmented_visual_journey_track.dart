import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/courses/models/course_models.dart';

class SegmentedVisualJourneyTrack extends StatelessWidget {
  const SegmentedVisualJourneyTrack({
    super.key,
    required this.sessions,
    this.onSegmentTap,
  });

  final List<CourseSession> sessions;
  final ValueChanged<CourseSession>? onSegmentTap;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 14,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalCount = sessions.length;
          final gap = totalCount > 20 ? 1.0 : 2.0;
          final totalGapWidth = (totalCount - 1) * gap;
          final segmentWidth = ((constraints.maxWidth - totalGapWidth) / totalCount).clamp(3.0, 40.0);

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(totalCount, (idx) {
                final session = sessions[idx];
                Color color;
                if (session.isCompleted) {
                  color = Colors.green;
                } else if (session.isSkipped) {
                  color = Colors.amber.shade700;
                } else {
                  color = colors.border.withValues(alpha: 0.4);
                }

                return GestureDetector(
                  onTap: () => onSegmentTap?.call(session),
                  child: Container(
                    width: segmentWidth,
                    height: 10,
                    margin: EdgeInsets.only(left: idx < totalCount - 1 ? gap : 0),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }
}
