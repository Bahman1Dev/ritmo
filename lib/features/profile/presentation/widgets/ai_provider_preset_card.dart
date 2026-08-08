import 'package:flutter/material.dart';
import 'package:ritmo/core/ai/ai_connection_models.dart';
import 'package:ritmo/core/theme/ritmo_colors.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/widgets/ritmo/ritmo_card.dart';
import 'package:ritmo/core/widgets/ritmo/ritmo_text_field.dart';
import 'package:url_launcher/url_launcher.dart';

class AiProviderPresetCard extends StatelessWidget {
  const AiProviderPresetCard({
    super.key,
    required this.preset,
    required this.isSelected,
    required this.onSelect,
    required this.hasApiKey,
    required this.accountIdController,
    this.onAccountIdChanged,
  });

  final AiProviderPreset preset;
  final bool isSelected;
  final VoidCallback onSelect;
  final bool hasApiKey;
  final TextEditingController accountIdController;
  final ValueChanged<String>? onAccountIdChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: RitmoSpacing.sm),
      child: RitmoCard(
        isSelected: isSelected,
        onTap: onSelect,
        padding: const EdgeInsets.all(RitmoSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Circular Brand Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: preset.brandColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.cloud_outlined,
                      color: preset.brandColor,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: RitmoSpacing.md),

                // Name & Tagline
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            preset.nameFa,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                          if (preset.worksInIranWithoutVpn) ...[
                            const SizedBox(width: RitmoSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.success.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(RitmoRadius.pill),
                              ),
                              child: Text(
                                'بدون فیلترشکن',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: colors.success,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        preset.taglineFa,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ],
                  ),
                ),

                // Selection check
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: colors.primary,
                    size: 22,
                  ),
              ],
            ),

            // Link to get API Key if selected & key is empty
            if (isSelected && !hasApiKey && preset.keyUrl.isNotEmpty) ...[
              const SizedBox(height: RitmoSpacing.sm),
              InkWell(
                onTap: () async {
                  final uri = Uri.parse(preset.keyUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                borderRadius: BorderRadius.circular(RitmoRadius.chip),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_new_rounded, size: 14, color: colors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'دریافت کلید از ${preset.nameFa}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                          fontFamily: 'Vazirmatn',
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Cloudflare Account ID Field
            if (isSelected && preset.needsAccountId) ...[
              const SizedBox(height: RitmoSpacing.md),
              RitmoTextField(
                label: 'شناسهٔ حساب Cloudflare (Account ID)',
                icon: Icons.account_circle_outlined,
                controller: accountIdController,
                onChanged: onAccountIdChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
