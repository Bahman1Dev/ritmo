import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/engines/cycle_engine.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/cycle/presentation/widgets/ai_cycle_assistant_sheet.dart';

class CycleSosSection extends StatelessWidget {

  const CycleSosSection({
    super.key,
    required this.engineOutput,
    required this.dayLogs,
    required this.settings,
    required this.phase,
  });
  final CycleEngineOutput? engineOutput;
  final List<Map<String, dynamic>> dayLogs;
  final Map<String, String> settings;
  final CyclePhase phase;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    var emoji = '🆘';
    var title = 'کمک فوری تسکین درد (SOS)';
    var subtitle = 'راهکارها و پوزیشن‌های فیزیکی برای تسکین سریع دردهای قاعدگی';
    var themeColor = const Color(0xffEC4899);

    if (phase == CyclePhase.ovulation) {
      emoji = '✨';
      title = 'سلامت و شادابی در فاز باروری';
      subtitle = 'راهکارها و رژیم‌های غذایی برای استفاده حداکثری از اوج شادابی بدنی';
      themeColor = const Color(0xff06B6D4);
    } else if (phase == CyclePhase.luteal) {
      emoji = '💆';
      title = 'مدیریت علائم پیش‌قاعدگی (PMS)';
      subtitle = 'راهکارهای خانگی برای بهبود خلق‌وخو و تسکین اسپاسم‌های اولیه';
      themeColor = const Color(0xffEC4899);
    } else if (phase == CyclePhase.follicular) {
      emoji = '⚡';
      title = 'تقویت انرژی و روتین فاز فولیکولار';
      subtitle = 'راهکارهای مناسب برای برنامه‌ریزی فعالیت‌ها و ارتقای توان فیزیکی';
      themeColor = const Color(0xff8B5CF6);
    }

    return SizedBox(
      width: double.infinity,
      child: RitmoTheme.glassCardLight(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showSosBottomSheet(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: themeColor.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 13,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_left,
                  color: colors.textSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSosBottomSheet(BuildContext context) {
    final colors = context.colors;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        var sheetTitle = 'راهکارهای سریع تسکین درد';
        var emoji = '🆘';
        if (phase == CyclePhase.ovulation) {
          sheetTitle = 'راهنمای بهبود باروری و شادابی';
          emoji = '✨';
        } else if (phase == CyclePhase.luteal) {
          sheetTitle = 'مدیریت و تسکین علائم پیش‌قاعدگی';
          emoji = '💆';
        } else if (phase == CyclePhase.follicular) {
          sheetTitle = 'راهنمای تقویت توان و انرژی بدنی';
          emoji = '⚡';
        }

        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.65),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black26,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(emoji, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(
                              sheetTitle,
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(CupertinoIcons.clear_circled_solid, color: colors.textSecondary),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildAiAssistantCard(context),
                        const SizedBox(height: 20),
                        ..._buildPhaseSpecificContent(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
      },
    );
  }

  List<Widget> _buildPhaseSpecificContent(BuildContext context) {
    final colors = context.colors;

    if (phase == CyclePhase.ovulation) {
      return [
        _buildSectionHeader(context, '🏃 بیشترین بهره‌وری از اوج انرژی فیزیکی'),
        const SizedBox(height: 12),
        _buildPositionCard(
          context,
          title: 'ورزش‌های قدرتی و هوازی شدید (HIIT)',
          description: 'به دلیل بالا بودن سطح استروژن و تستوسترون در فاز تخمک‌گذاری، قدرت عضلانی و هماهنگی بدنی شما در اوج است. بهترین زمان برای دویدن، بدنسازی و ورزش‌های چالشی.',
          icon: CupertinoIcons.sportscourt,
        ),
        _buildPositionCard(
          context,
          title: 'برنامه‌ریزی کارهای مهم و مذاکره',
          description: 'افزایش طبیعی اعتماد به نفس و مهارت‌های ارتباطی در این دوره، انجام کارهای اجتماعی و جلسات مهم کاری را بسیار اثربخش‌تر می‌کند.',
          icon: CupertinoIcons.lightbulb,
        ),
        const SizedBox(height: 20),
        _buildSectionHeader(context, '🥗 مراقبت‌های سلامتی فاز باروری'),
        const SizedBox(height: 12),
        _buildHomeRemedyCard(
          context,
          title: 'تغذیه سبک و سرشار از آنتی‌اکسیدان 🥦',
          description: 'مصرف غلات کامل، دانه‌های کنجد و آفتابگردان، میوه‌های تازه و سبزیجات برگ‌پهن به کبد در پردازش استروژن‌های اضافی کمک می‌کند.',
        ),
        _buildHomeRemedyCard(
          context,
          title: 'آبرسانی و هیدراتاسیون کامل پوست 💧',
          description: 'نوشیدن آب کافی و دمنوش‌های سرد نعناع یا بهارنارنج، علاوه بر شادابی بیشتر، به بهبود کیفیت مخاط دهانه رحم کمک می‌کند.',
        ),
      ];
    } else if (phase == CyclePhase.luteal) {
      return [
        _buildSectionHeader(context, '🧘 بهبود آرامش ذهن و کاهش نوسانات خلقی'),
        const SizedBox(height: 12),
        _buildPositionCard(
          context,
          title: 'تنفس عمیق شکمی ۴-۷-۸ و یوگا 🧘',
          description: 'فعال‌سازی سیستم عصبی پاراسمپاتیک برای مهار ترشح کورتیزول و کاهش اضطراب، خشم و تنش‌های روانی پیش از قاعدگی.',
        ),
        _buildPositionCard(
          context,
          title: 'تمرینات کششی سبک و پیلاتس 🤸',
          description: 'کشش ملایم لگن و فیله کمر به کاهش گرفتگی‌های زودرس و تسکین اسپاسم‌های شکمی ملایم پیش‌قاعدگی کمک می‌کند.',
        ),
        const SizedBox(height: 20),
        _buildSectionHeader(context, '🫖 راهکارهای تغذیه‌ای برای کنترل علائم'),
        const SizedBox(height: 12),
        _buildHomeRemedyCard(
          context,
          title: 'کاهش شدید مصرف نمک و کافئین ☕',
          description: 'نمک کمتر از احتباس مایعات، نفخ و درد سینه جلوگیری می‌کند. کافئین کمتر نیز تحریک‌پذیری و نوسانات خلق را کنترل می‌کند.',
        ),
        _buildHomeRemedyCard(
          context,
          title: 'دمنوش گل‌گاوزبان یا بابونه 🫖',
          description: 'دمنوش‌های آرام‌بخش عضلات و اعصاب که ترجیحاً ۲ تا ۳ روز قبل از موعد پریود مصرف شوند تا خواب باکیفیتی داشته باشید.',
        ),
      ];
    } else if (phase == CyclePhase.follicular) {
      return [
        _buildSectionHeader(context, '💪 برنامه‌ریزی فعالیت‌ها و افزایش تدریجی تحرک'),
        const SizedBox(height: 12),
        _buildPositionCard(
          context,
          title: 'شروع برنامه‌های ورزشی و تحرک قدرتی 🏃',
          description: 'استروژن رو به افزایش است، بنابراین زمان عالی برای تمرینات هوازی، ورزش‌های استقامتی متوسط و پیاده‌روی سریع است.',
        ),
        _buildPositionCard(
          context,
          title: 'شروع پروژه‌های جدید و یادگیری',
          description: 'پس از پایان پریود، تمرکز ذهنی و تمایل به یادگیری افزایش می‌یابد. زمان بسیار خوبی برای خواندن کتاب‌های جدید یا کارهای فکری خلاقانه است.',
          icon: CupertinoIcons.lightbulb,
        ),
        const SizedBox(height: 20),
        _buildSectionHeader(context, '🍊 تغذیه فاز رشد و انرژی‌بخش'),
        const SizedBox(height: 12),
        _buildHomeRemedyCard(
          context,
          title: 'غذاهای غنی از آهن و ویتامین C 🥑',
          description: 'برای جبران آهن از دست رفته در قاعدگی قبلی، اسفناج، حبوبات، مغزها و مرکبات تازه را به رژیم غذایی اضافه کنید.',
        ),
        _buildHomeRemedyCard(
          context,
          title: 'مصرف پروبیوتیک‌ها و هضم بهتر 🥕',
          description: 'غذاهای تخمیری، ماست پروبیوتیک و مواد غذایی فیبردار به کارکرد بهتر سیستم گوارش و طراوت پوست در این دوره کمک می‌کنند.',
        ),
      ];
    } else {
      return [
        _buildSectionHeader(context, '🧘 پوزیشن‌های تسکین درد رحم'),
        const SizedBox(height: 12),
        _buildPositionCard(
          context,
          title: "پوزیشن کودک (Child's Pose) 🧒",
          description: 'روی زانو بنشینید، بالاتنه را جلو ببرید و پیشانی را روی زمین بگذارید. دست‌ها را جلو بکشید. ۱ تا ۳ دقیقه نگه دارید. فشار از عضلات شکم و کمر کم می‌شود.',
        ),
        _buildPositionCard(
          context,
          title: 'پوزیشن گربه-گاو (Cat-Cow) 🐱',
          description: 'چهار دست و پا، سر بالا + کمر گود (گاو) ← سر پایین + کمر قوس (گربه). ۱۰ بار تکرار. گردش خون لگن بهتر می‌شود.',
        ),
        _buildPositionCard(
          context,
          title: 'پوزیشن پروانه (Butterfly) 🦋',
          description: 'نشسته، کف پاها را به هم بچسبانید، زانوها را آرام بالا و پایین ببرید. عضلات لگن شل می‌شوند.',
        ),
        _buildPositionCard(
          context,
          title: 'پوزیشن جنینی (Fetal Position)',
          description: 'به پهلو بخوابید، زانوها را به سینه نزدیک کنید. عضلات شکم ریلکس می‌شوند.',
          icon: CupertinoIcons.moon_stars,
        ),
        const SizedBox(height: 20),
        _buildSectionHeader(context, '🫖 راهکارهای سریع خانگی'),
        const SizedBox(height: 12),
        _buildHomeRemedyCard(
          context,
          title: 'دمنوش‌های ضداسپاسم 🫖',
          description: 'دمنوش بابونه یا زنجبیل. ۱ قاشق چایخوری در آب جوش، ۱۰ دقیقه دم بکشد. ضد اسپاسم و آرام‌بخش عضلات صاف رحم.',
        ),
        _buildHomeRemedyCard(
          context,
          title: 'کمپرس گرم 🔥',
          description: 'یک کیسه آبگرم یا حوله گرم روی شکم یا کمر بگذارید. ۱۵-۲۰ دقیقه. گرما جریان خون را بهبود داده و عضلات منقبض را شل می‌کند.',
        ),
        _buildHomeRemedyCard(
          context,
          title: 'ماساژ ملایم شکم 🫧',
          description: 'با حرکات دایره‌ای آرام، شکم را در جهت عقربه‌های ساعت ماساژ دهید. استفاده از روغن بابونه یا اسطوخودوس به تسکین کمک بیشتری می‌کند.',
        ),
        _buildHomeRemedyCard(
          context,
          title: 'تنفس عمیق ۴-۷-۸ 🧘',
          description: '۴ ثانیه نفس بکشید، ۷ ثانیه نگه دارید، ۸ ثانیه بازدم. ۴ بار تکرار. سیستم عصبی پاراسمپاتیک را فعال و ادراک درد را کاهش می‌دهد.',
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xffEC4899).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffEC4899).withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              const Icon(CupertinoIcons.info_circle_fill, color: Color(0xffEC4899), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'همراه عزیز ریتمو، اگر درد شما بسیار شدید و غیرقابل تحمل است یا با علائمی چون تب یا خونریزی بسیار شدید همراه است، حتماً با پزشک مشورت کنید. 🌸',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 14,
                    color: colors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ];
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final colors = context.colors;
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Vazirmatn',
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: colors.textPrimary,
      ),
    );
  }

  Widget _buildPositionCard(BuildContext context, {required String title, required String description, IconData? icon}) {
    final colors = context.colors;
    var themeColor = const Color(0xffEC4899);
    if (phase == CyclePhase.ovulation) {
      themeColor = const Color(0xff06B6D4);
    } else if (phase == CyclePhase.follicular) {
      themeColor = const Color(0xff8B5CF6);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeColor.withValues(alpha: 0.1), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: themeColor, size: 16),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: themeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 13,
                color: colors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeRemedyCard(BuildContext context, {required String title, required String description, IconData? icon}) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05), 
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: const Color(0xffEC4899), size: 16),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 13,
                color: colors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiAssistantCard(BuildContext context) {
    var startColor = const Color(0xffEC4899);
    var endColor = const Color(0xffF472B6);
    if (phase == CyclePhase.ovulation) {
      startColor = const Color(0xff06B6D4);
      endColor = const Color(0xff22D3EE);
    } else if (phase == CyclePhase.follicular) {
      startColor = const Color(0xff8B5CF6);
      endColor = const Color(0xffA78BFA);
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: startColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _handleAiAssistantTap(context),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.sparkles,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'گفتگو با دستیار هوشمند ریتمو 🔮',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'مشاوره اختصاصی و خودمراقبتی هوشمند برای تسکین درد و ارتقای سلامتی ✨',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(CupertinoIcons.chevron_left, color: Colors.white, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleAiAssistantTap(BuildContext context) {
    showCycleAiConsentSheet(
      context,
      engineOutput: engineOutput,
      dayLogs: dayLogs,
      settings: settings,
      onConsentGranted: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => AiCycleAssistantSheet(
            engineOutput: engineOutput,
            dayLogs: dayLogs,
            settings: settings,
          ),
        );
      },
    );
  }
}
