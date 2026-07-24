import 'package:flutter/material.dart';
import 'package:ritmo/features/calendar/presentation/models/now_pill_view_model.dart';

class NowPill extends StatelessWidget {
  const NowPill({
    super.key,
    required this.viewModel,
    this.onTapPill,
    this.onTapComplete,
    this.onTapJumpNow,
  });

  final NowPillViewModel viewModel;
  final VoidCallback? onTapPill;
  final VoidCallback? onTapComplete;
  final VoidCallback? onTapJumpNow;

  @override
  Widget build(BuildContext context) {
    if (!viewModel.isVisible || viewModel.targetItem == null) {
      return const SizedBox.shrink();
    }

    final item = viewModel.targetItem!;
    final isCurrent = viewModel.isCurrent;
    final badgeColor = isCurrent ? Colors.green.shade700 : Colors.amber.shade800;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTapPill,
        borderRadius: BorderRadius.circular(24.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceElevated,
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(
              color: badgeColor.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  viewModel.statusLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      viewModel.timeLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (onTapJumpNow != null)
                IconButton(
                  icon: const Icon(Icons.my_location, size: 18),
                  onPressed: onTapJumpNow,
                  tooltip: 'Jump to current time',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
              if (onTapComplete != null && !item.isCompleted)
                IconButton(
                  icon: const Icon(Icons.check_circle_outline, size: 20, color: Colors.green),
                  onPressed: onTapComplete,
                  tooltip: 'Complete item',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

extension _ThemeSurface on ColorScheme {
  Color get surfaceElevated => brightness == Brightness.dark
      ? const Color(0xFF242830)
      : const Color(0xFFFFFFFF);
}
