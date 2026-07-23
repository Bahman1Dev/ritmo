import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/services/payment_gateway.dart';
import 'package:ritmo/core/services/premium_service.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/core/ux/ritmo_snackbar.dart';

class PremiumUpgradeSheet extends StatefulWidget {
  const PremiumUpgradeSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PremiumUpgradeSheet(),
    );
  }

  @override
  State<PremiumUpgradeSheet> createState() => _PremiumUpgradeSheetState();
}

class _PremiumUpgradeSheetState extends State<PremiumUpgradeSheet> {
  String _selectedPlan = 'premium_yearly'; // premium_1month, premium_3month, premium_6month, premium_yearly, premium_lifetime
  bool _isLoading = false;
  Map<String, String> _prices = {
    'premium_1month': '۹۹,۰۰۰ تومان',
    'premium_3month': '۱۹۹,۰۰۰ تومان',
    'premium_6month': '۳۴۹,۰۰۰ تومان',
    'premium_yearly': '۴۶۹,۰۰۰ تومان',
    'premium_lifetime': '۷۹۹,۰۰۰ تومان',
  };

  @override
  void initState() {
    super.initState();
    _loadPrices();
  }

  Future<void> _loadPrices() async {
    try {
      final prices = await PaymentService.gateway.getProductDetails([
        'premium_1month',
        'premium_3month',
        'premium_6month',
        'premium_yearly',
        'premium_lifetime',
      ]);
      if (prices.isNotEmpty && mounted) {
        setState(() {
          _prices = prices;
        });
      }
    } catch (_) {}
  }

  Future<void> _purchase() async {
    setState(() => _isLoading = true);
    RitmoHaptics.tap();

    try {
      final result = await PaymentService.gateway.purchase(_selectedPlan);
      if (result.success) {
        // Activate locally
        var durationDays = 0;
        if (_selectedPlan == 'premium_1month') {
          durationDays = 30;
        } else if (_selectedPlan == 'premium_3month') {
          durationDays = 90;
        } else if (_selectedPlan == 'premium_6month') {
          durationDays = 180;
        } else if (_selectedPlan == 'premium_yearly') {
          durationDays = 365;
        } else if (_selectedPlan == 'premium_lifetime') {
          durationDays = 0; // Lifetime
        }

        const storeName = String.fromEnvironment('FLAVOR', defaultValue: 'bazaar');
        await PremiumService.instance.activatePremium(
          sku: _selectedPlan,
          durationDays: durationDays,
          storeName: storeName,
        );

        if (mounted) {
          RitmoSnackbar.success(
            context,
            'خرید شما با موفقیت انجام شد! به جمع پرمیوم ریتمو خوش آمدید. 🎉',
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          RitmoSnackbar.error(
            context,
            result.errorMessage ?? 'خرید با خطا مواجه شد.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        RitmoSnackbar.error(
          context,
          'خطایی رخ داد: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);
    RitmoHaptics.tap();

    try {
      final purchases = await PaymentService.gateway.restorePurchases();
      if (purchases.isEmpty) {
        if (mounted) {
          RitmoSnackbar.error(
            context,
            'هیچ خریدی برای بازیابی پیدا نشد.',
          );
        }
        return;
      }

      // Check if any valid purchase exists
      PurchaseInfo? activePurchase;
      for (final p in purchases) {
        if (p.sku == 'premium_lifetime' ||
            p.sku == 'premium_yearly' ||
            p.sku == 'premium_6month' ||
            p.sku == 'premium_3month' ||
            p.sku == 'premium_1month') {
          activePurchase = p;
          break;
        }
      }

      if (activePurchase != null) {
        var durationDays = 0;
        if (activePurchase.sku == 'premium_1month') {
          durationDays = 30;
        } else if (activePurchase.sku == 'premium_3month') {
          durationDays = 90;
        } else if (activePurchase.sku == 'premium_6month') {
          durationDays = 180;
        } else if (activePurchase.sku == 'premium_yearly') {
          durationDays = 365;
        }

        const storeName = String.fromEnvironment('FLAVOR', defaultValue: 'bazaar');
        await PremiumService.instance.activatePremium(
          sku: activePurchase.sku,
          durationDays: durationDays,
          storeName: storeName,
        );

        if (mounted) {
          RitmoSnackbar.success(
            context,
            'اشتراک شما با موفقیت بازیابی شد. 💎',
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          RitmoSnackbar.error(
            context,
            'هیچ خرید معتبری پیدا نشد.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        RitmoSnackbar.error(
          context,
          'خطا در بازیابی خریدها: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final size = MediaQuery.of(context).size;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: size.height * 0.85,
        decoration: BoxDecoration(
          color: colors.bg,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          border: Border.all(color: colors.border.withValues(alpha: 0.15)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Pull handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Icon 💎
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xffFFD700), Color(0xffFFA500), Color(0xffFF8C00)],
              ).createShader(bounds),
              child: const Icon(
                Icons.diamond,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              'ارتقا به نسخه پرمیوم ریتمو',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'باز کردن قفل تمام ویژگی‌های هوشمند اپلیکیشن',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 12,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Features list
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildFeatureRow(context, '🧠', 'هوش مصنوعی نامحدود', 'دستیار شخصی، تحلیل‌های روزانه، چت هوشمند و تحلیل ریتم زیستی'),
                    _buildFeatureRow(context, '📅', 'روتین و اهداف نامحدود', 'ایجاد بیش از ۱۵ روتین فعال و ۳ هدف همزمان بدون محدودیت'),
                    _buildFeatureRow(context, '🔄', 'بازچینش هوشمند زمان', 'حل خودکار تداخل‌های زمانی با موتور تحلیل زمان ریتمو'),
                    _buildFeatureRow(context, '🎓', 'ماژول‌های تخصصی دوره‌ها و کنکور', 'دسترسی کامل به زمان‌بندی هوشمند مطالعه و مدیریت کنکور'),
                    _buildFeatureRow(context, '📊', 'هوش رفتاری پیشرفته', 'دریافت همبستگی‌های پیشرفته بین خواب، انرژی، نماز و کارها'),
                    _buildFeatureRow(context, '🚫', 'حذف تبلیغات مزاحم', 'استفاده از تمام بخش‌های برنامه در محیطی کاملاً خلوت و بدون تبلیغ'),
                    const SizedBox(height: 24),

                    // Plans selection
                    _buildPlanCard(
                      sku: 'premium_1month',
                      title: 'پلان ۱ ماهه',
                      price: _prices['premium_1month'] ?? '۹۹,۰۰۰ تومان',
                      isRecommended: false,
                    ),
                    const SizedBox(height: 12),
                    _buildPlanCard(
                      sku: 'premium_3month',
                      title: 'پلان ۳ ماهه',
                      price: _prices['premium_3month'] ?? '۱۹۹,۰۰۰ تومان',
                      isRecommended: false,
                      discountLabel: '۳۳٪ تخفیف',
                    ),
                    const SizedBox(height: 12),
                    _buildPlanCard(
                      sku: 'premium_6month',
                      title: 'پلان ۶ ماهه',
                      price: _prices['premium_6month'] ?? '۳۴۹,۰۰۰ تومان',
                      isRecommended: false,
                      discountLabel: '۴۱٪ تخفیف',
                    ),
                    const SizedBox(height: 12),
                    _buildPlanCard(
                      sku: 'premium_yearly',
                      title: 'پلان سالانه',
                      price: _prices['premium_yearly'] ?? '۴۶۹,۰۰۰ تومان',
                      isRecommended: true,
                      discountLabel: '۶۰٪ تخفیف',
                    ),
                    const SizedBox(height: 12),
                    _buildPlanCard(
                      sku: 'premium_lifetime',
                      title: 'دسترسی مادام‌العمر',
                      price: _prices['premium_lifetime'] ?? '۷۹۹,۰۰۰ تومان',
                      isRecommended: false,
                      discountLabel: 'ارزش فوق‌العاده',
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Action buttons
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (kDebugMode) ...[
                  TextButton(
                    onPressed: () async {
                      final active = !PremiumService.instance.isDebugMockActive;
                      await PremiumService.instance.toggleDebugMock(active);
                      setState(() {});
                      if (context.mounted) {
                        if (active) {
                          RitmoSnackbar.success(context, 'شبیه‌ساز پرمیوم فعال شد.');
                        } else {
                          RitmoSnackbar.warning(context, 'شبیه‌ساز غیرفعال شد.');
                        }
                      }
                    },
                    child: Text(
                      PremiumService.instance.isDebugMockActive ? 'غیرفعال‌سازی شبیه‌ساز تست' : 'فعال‌سازی تست (شبیه‌ساز)',
                      style: const TextStyle(fontFamily: 'Vazirmatn', color: Colors.amber),
                    ),
                  ),
                ],
                ElevatedButton(
                  onPressed: _isLoading ? null : _purchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : const Text(
                          'تایید و خرید پرمیوم',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _isLoading ? null : _restorePurchases,
                  child: Text(
                    'بازیابی خریدهای قبلی',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      color: colors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(BuildContext context, String emoji, String title, String desc) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 11,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String sku,
    required String title,
    required String price,
    required bool isRecommended,
    String? discountLabel,
  }) {
    final colors = context.colors;
    final isSelected = _selectedPlan == sku;

    return GestureDetector(
      onTap: () {
        RitmoHaptics.tap();
        setState(() {
          _selectedPlan = sku;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? colors.primary.withValues(alpha: 0.05) : colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (discountLabel != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            discountLabel,
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 9,
                              color: colors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xffFFA500),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'پیشنهاد ما',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    price,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? colors.primary : colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
              color: isSelected ? colors.primary : colors.textSecondary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
