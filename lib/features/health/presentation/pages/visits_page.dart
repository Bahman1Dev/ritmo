import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/features/health/presentation/widgets/doctor_visit_summary_sheet.dart';
import 'package:ritmo/features/health/presentation/widgets/doctor_visits_section.dart';
import 'package:ritmo/l10n/app_localizations.dart';

class VisitsPage extends StatelessWidget {
  const VisitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    const identityColor = Color(0xff10B981); // Visits Green

    void openDoctorVisitSummarySheet() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const Directionality(
          textDirection: TextDirection.rtl,
          child: DoctorVisitSummarySheet(),
        ),
      );
    }

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
                child: const Icon(CupertinoIcons.calendar_badge_plus, color: identityColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.doctorVisits,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: TextButton.icon(
                onPressed: openDoctorVisitSummarySheet,
                icon: const Icon(Icons.description_outlined, size: 16, color: Color(0xff10B981)),
                label: const Text(
                  'خلاصه برای پزشک',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xff10B981),
                  ),
                ),
              ),
            ),
          ],
          centerTitle: false,
        ),
        body: const SingleChildScrollView(
          child: DoctorVisitsSection(),
        ),
      ),
    );
  }
}
