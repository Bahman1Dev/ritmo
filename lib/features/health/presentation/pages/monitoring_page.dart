import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/health/presentation/widgets/blood_pressure_section.dart';
import 'package:ritmo/features/health/presentation/widgets/blood_sugar_section.dart';
import 'package:ritmo/features/health/presentation/widgets/vital_signs_section.dart';
import 'package:ritmo/l10n/app_localizations.dart';

class MonitoringPage extends StatefulWidget {

  const MonitoringPage({
    super.key,
    this.initialTab = 0,
  });
  final int initialTab;

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  late int _activeTab;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    const identityColor = Color(0xffF59E0B); // Monitoring Amber

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colors.bg,
        appBar: AppBar(
          backgroundColor: colors.bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: identityColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.waveform_path, color: identityColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.healthMonitoring,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          centerTitle: false,
        ),
        body: Column(
          children: [
            // Custom Segmented Switcher
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: colors.card.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.border.withValues(alpha: 0.5)),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    _buildSegmentButton(0, l10n.bloodSugarTitle),
                    _buildSegmentButton(1, l10n.bloodPressureTitle),
                    _buildSegmentButton(2, l10n.vitalSignsTitle),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Tabs Content
            Expanded(
              child: SingleChildScrollView(
                child: IndexedStack(
                  index: _activeTab,
                  children: const [
                    BloodSugarSection(),
                    BloodPressureSection(),
                    VitalSignsSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton(int index, String label) {
    final colors = context.colors;
    final isSelected = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTab = index;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xffF59E0B) : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : colors.textSecondary,
              fontFamily: 'Vazirmatn',
            ),
          ),
        ),
      ),
    );
  }
}
