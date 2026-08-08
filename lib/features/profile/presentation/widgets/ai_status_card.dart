import 'package:flutter/material.dart';
import 'package:ritmo/core/ai/ai_connection_models.dart';
import 'package:ritmo/core/theme/ritmo_colors.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/widgets/ritmo/ritmo_button.dart';
import 'package:ritmo/core/widgets/ritmo/ritmo_hero_card.dart';

enum AiHealth {
  connected,
  untested,
  failing,
  unconfigured,
}

class AiStatusCard extends StatelessWidget {
  const AiStatusCard({
    super.key,
    required this.health,
    required this.providerName,
    required this.effectiveModel,
    required this.lastTestLatencyMs,
    required this.lastTestAt,
    required this.errorMessage,
    required this.isTesting,
    required this.onTest,
    this.cloudConsentGranted = true,
  });

  final AiHealth health;
  final String providerName;
  final String effectiveModel;
  final int? lastTestLatencyMs;
  final int? lastTestAt;
  final String? errorMessage;
  final bool isTesting;
  final VoidCallback onTest;
  final bool cloudConsentGranted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final Color statusColor;
    final String statusTitle;

    switch (health) {
      case AiHealth.connected:
        statusColor = colors.success;
        statusTitle = 'متصل و آماده';
        break;
      case AiHealth.untested:
        statusColor = colors.textSecondary;
        statusTitle = 'هنوز آزمایش نشده';
        break;
      case AiHealth.failing:
        statusColor = colors.warning;
        statusTitle = 'مشکل در اتصال';
        break;
      case AiHealth.unconfigured:
        statusColor = colors.textTertiary;
        statusTitle = 'پیکربندی نشده';
        break;
    }

    String timeAgoText() {
      if (lastTestAt == null || lastTestAt! <= 0) return '';
      final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(lastTestAt!));
      final latencyStr = lastTestLatencyMs != null ? ' · ${toPersianDigits(lastTestLatencyMs.toString())} میلی‌ثانیه' : '';
      if (diff.inMinutes < 1) {
        return 'آخرین آزمایش: لحظاتی پیش$latencyStr';
      } else if (diff.inHours < 1) {
        return 'آخرین آزمایش: ${toPersianDigits(diff.inMinutes.toString())} دقیقه پیش$latencyStr';
      } else if (diff.inDays < 1) {
        return 'آخرین آزمایش: ${toPersianDigits(diff.inHours.toString())} ساعت پیش$latencyStr';
      } else {
        return 'آخرین آزمایش: ${toPersianDigits(diff.inDays.toString())} روز پیش$latencyStr';
      }
    }

    return RitmoHeroCard(
      moduleColor: statusColor,
      showGlow: health == AiHealth.connected,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Status dot + Title
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (health == AiHealth.connected)
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.5),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: RitmoSpacing.sm),
              Text(
                statusTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
          const SizedBox(height: RitmoSpacing.sm),

          // 2. Provider name & Effective model
          if (providerName.isNotEmpty || effectiveModel.isNotEmpty)
            Text(
              'سرویس‌دهنده: $providerName · مدل ارسالی: $effectiveModel',
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
                fontFamily: 'Vazirmatn',
              ),
            ),
          const SizedBox(height: RitmoSpacing.xs),

          // 3. Last test or error message
          if (health == AiHealth.connected && timeAgoText().isNotEmpty)
            Text(
              timeAgoText(),
              style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary,
                fontFamily: 'Vazirmatn',
              ),
            )
          else if (health == AiHealth.failing && errorMessage != null && errorMessage!.isNotEmpty)
            Text(
              errorMessage!,
              style: TextStyle(
                fontSize: 12,
                color: colors.warning,
                fontFamily: 'Vazirmatn',
              ),
            ),

          if (!cloudConsentGranted) ...[
            const SizedBox(height: RitmoSpacing.sm),
            Container(
              padding: const EdgeInsets.all(RitmoSpacing.sm),
              decoration: BoxDecoration(
                color: colors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(RitmoRadius.chip),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: colors.warning, size: 16),
                  const SizedBox(width: RitmoSpacing.xs),
                  Expanded(
                    child: Text(
                      'رضایت ابری دستیار غیرفعال است (درخواست‌ها ممکن است پردازش نشوند).',
                      style: TextStyle(fontSize: 11, color: colors.warning, fontFamily: 'Vazirmatn'),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: RitmoSpacing.md),

          // 4. Test button
          RitmoPrimaryButton(
            label: 'آزمایش اتصال',
            icon: Icons.bolt_rounded,
            isLoading: isTesting,
            fullWidth: true,
            onPressed: onTest,
          ),
        ],
      ),
    );
  }
}
