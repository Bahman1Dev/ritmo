import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/energy/models/energy_mood_models.dart';

class EnergyTodaySection extends StatelessWidget {

  const EnergyTodaySection({
    super.key,
    required this.todayEnergyLogs,
    required this.todayMoodLogs,
    required this.currentEnergy,
    required this.defaultEnergyLevel,
  });
  final List<EnergyLog> todayEnergyLogs;
  final List<MoodLog> todayMoodLogs;
  final double currentEnergy;
  final String defaultEnergyLevel;

  String _toPersianDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var result = input;
    for (var i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], persian[i]);
    }
    return result;
  }

  String _formatTime(int epochMillis) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epochMillis);
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return _toPersianDigits('$h:$m');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final today = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section: Energy Curve Chart
        RitmoTheme.glassCardLight(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(CupertinoIcons.graph_square, color: Color(0xffEC4899), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'نوسان انرژی فیزیکی امروز',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Curve Container
                Container(
                  height: 140,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: CustomPaint(
                    painter: EnergyCurvePainter(
                      logs: todayEnergyLogs,
                      today: today,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Timeline Labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_toPersianDigits('۰۰:۰۰'), style: const TextStyle(fontSize: 9, color: Colors.white30, fontFamily: 'Vazirmatn')),
                    Text(_toPersianDigits('۰۶:۰۰'), style: const TextStyle(fontSize: 9, color: Colors.white30, fontFamily: 'Vazirmatn')),
                    Text(_toPersianDigits('۱۲:۰۰'), style: const TextStyle(fontSize: 9, color: Colors.white30, fontFamily: 'Vazirmatn')),
                    Text(_toPersianDigits('۱۸:۰۰'), style: const TextStyle(fontSize: 9, color: Colors.white30, fontFamily: 'Vazirmatn')),
                    Text(_toPersianDigits('۲۴:۰۰'), style: const TextStyle(fontSize: 9, color: Colors.white30, fontFamily: 'Vazirmatn')),
                  ],
                ),
                if (todayEnergyLogs.isEmpty) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'تازه شروع کردی! با ثبت وضعیت در طول روز، منحنی نوسان انرژی فیزیکی شما در این بخش رسم می‌شود 📈',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10.5, color: colors.textSecondary, fontFamily: 'Vazirmatn', height: 1.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Section: Today's Mood Logs
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'احوال روحی ثبت‌شده امروز',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn'),
          ),
        ),
        const SizedBox(height: 10),
        
        if (todayMoodLogs.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'امروز هنوز هیچ احوال روحی ثبت نکرده‌ای 🌿',
                style: TextStyle(fontSize: 11, color: colors.textSecondary, fontFamily: 'Vazirmatn'),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: todayMoodLogs.length,
            itemBuilder: (context, index) {
              final log = todayMoodLogs[index];

              return Card(
                color: Colors.white.withValues(alpha: 0.015),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
                ),
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time
                      Text(
                        _formatTime(log.loggedAt),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xffEC4899), fontFamily: 'Vazirmatn'),
                      ),
                      const SizedBox(width: 14),

                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'احساس: ${log.mood.emoji} ${log.mood.label}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Vazirmatn'),
                                ),
                                // Valence Indicator
                                Row(
                                  children: List.generate(5, (starIdx) {
                                    final filled = starIdx < log.valence;
                                    return Icon(
                                      filled ? CupertinoIcons.circle_fill : CupertinoIcons.circle,
                                      size: 7,
                                      color: filled ? const Color(0xffEC4899) : Colors.white12,
                                    );
                                  }),
                                ),
                              ],
                            ),
                            if (log.note != null && log.note!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                log.note!,
                                style: TextStyle(fontSize: 10.5, color: colors.textSecondary, fontFamily: 'Vazirmatn', height: 1.4),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class EnergyCurvePainter extends CustomPainter {

  EnergyCurvePainter({required this.logs, required this.today});
  final List<EnergyLog> logs;
  final DateTime today;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xffEC4899)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xffEC4899).withValues(alpha: 0.15),
          const Color(0xffEC4899).withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final dotPaint = Paint()
      ..color = const Color(0xffEC4899)
      ..style = PaintingStyle.fill;

    final ringPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1.0;

    // Draw horizontal grid lines
    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw vertical grid lines
    for (var i = 0; i <= 4; i++) {
      final x = size.width * i / 4;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    if (logs.isEmpty) {
      final y = size.height * (1.0 - 0.65);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint..color = Colors.white24);
      return;
    }

    final sortedLogs = List<EnergyLog>.from(logs)
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));

    final points = <Offset>[];
    final dayStart = DateTime(today.year, today.month, today.day);

    for (final log in sortedLogs) {
      final logTime = DateTime.fromMillisecondsSinceEpoch(log.loggedAt);
      final minutesFromStart = logTime.difference(dayStart).inMinutes;
      final x = (minutesFromStart / (24 * 60)) * size.width;
      final y = (1.0 - (log.energyLevel.score / 100.0)) * size.height;
      points.add(Offset(x, y));
    }

    if (points.length == 1) {
      final p = points.first;
      canvas.drawLine(Offset(0, p.dy), Offset(size.width, p.dy), paint);
      canvas.drawCircle(p, 5, dotPaint);
      canvas.drawCircle(p, 5, ringPaint);
      return;
    }

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final fillPath = Path.from(path);
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.lineTo(points.first.dx, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    canvas.drawPath(path, paint);

    for (final p in points) {
      canvas.drawCircle(p, 4, dotPaint);
      canvas.drawCircle(p, 4, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant EnergyCurvePainter oldDelegate) {
    return oldDelegate.logs.length != logs.length || oldDelegate.today != today;
  }
}
