import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';

class EnergyPatternsSection extends StatelessWidget {

  const EnergyPatternsSection({
    super.key,
    this.peakPerformanceWindow,
    this.mostProductiveWeekday,
    this.mostFatiguedWindow,
  });
  final String? peakPerformanceWindow;
  final String? mostProductiveWeekday;
  final String? mostFatiguedWindow;

  String _toPersianDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var result = input;
    for (var i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], persian[i]);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final hasData = peakPerformanceWindow != null ||
        mostProductiveWeekday != null ||
        mostFatiguedWindow != null;

    if (!hasData) {
      return RitmoTheme.glassCardLight(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          child: Column(
            children: [
              const Text(
                '🌿',
                style: TextStyle(fontSize: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                'هنوز در حالِ یادگیریِ الگوهای توام',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn'),
              ),
              const SizedBox(height: 8),
              Text(
                'با ثبت منظم وضعیت انرژی و احوال روحی در ساعات مختلف روزهای آینده، ریتمو الگوهای زیستی و اوج کارایی فیزیکی اختصاصی شما را استخراج خواهد کرد.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: colors.textSecondary, fontFamily: 'Vazirmatn', height: 1.6),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (peakPerformanceWindow != null) ...[
          _buildPatternCard(
            context: context,
            title: 'بازه اوج کارایی فیزیکی (پرانرژی‌ترین ساعت)',
            value: _toPersianDigits(peakPerformanceWindow!),
            description: 'در این بازه زمانی، سطح تمرکز و توان فیزیکی شما در بالاترین حد قرار دارد. پیشنهاد می‌شود سنگین‌ترین و مهم‌ترین فعالیت‌های امروز خود را در این زمان برنامه‌ریزی کنید.',
            icon: CupertinoIcons.sparkles,
            accentColor: Colors.amber,
          ),
          const SizedBox(height: 12),
        ],
        if (mostProductiveWeekday != null) ...[
          _buildPatternCard(
            context: context,
            title: 'پربارترین روز هفته',
            value: mostProductiveWeekday!,
            description: 'در این روز از هفته، بیشترین پیشرفت روتین‌ها و تعهدات روزانه شما به صورت کامل ثبت شده است.',
            icon: CupertinoIcons.calendar_today,
            accentColor: Colors.greenAccent,
          ),
          const SizedBox(height: 12),
        ],
        if (mostFatiguedWindow != null) ...[
          _buildPatternCard(
            context: context,
            title: 'بازه خستگی و افت انرژی بدنی',
            value: _toPersianDigits(mostFatiguedWindow!),
            description: 'در این بازه زمانی، انرژی فیزیکی بدنتان با افت طبیعی روبرو می‌شود. پیشنهاد می‌شود کارهای سبک‌تر را در این ساعت انجام داده یا استراحت کوتاهی در نظر بگیرید.',
            icon: CupertinoIcons.battery_25,
            accentColor: const Color(0xffF43F5E),
          ),
        ],
      ],
    );
  }

  Widget _buildPatternCard({
    required BuildContext context,
    required String title,
    required String value,
    required String description,
    required IconData icon,
    required Color accentColor,
  }) {
    final colors = context.colors;

    return RitmoTheme.glassCardLight(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 10.5, color: Colors.white54, fontFamily: 'Vazirmatn'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: accentColor, fontFamily: 'Vazirmatn'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(fontSize: 10.5, color: colors.textSecondary, fontFamily: 'Vazirmatn', height: 1.5),
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
