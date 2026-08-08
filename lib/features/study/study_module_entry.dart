import 'package:flutter/material.dart';
import 'package:ritmo/features/konkur/presentation/konkur_screen.dart';
import 'package:ritmo/features/study/data/study_settings_repository.dart';
import 'package:ritmo/features/study/presentation/study_home_screen.dart';

class StudyModuleEntry {
  const StudyModuleEntry._();

  static Future<void> open(BuildContext context) async {
    final settings = await StudySettingsRepository.instance.load();

    final Widget root = settings.konkurMode
        ? KonkurScreen(
            onSwitchToStudyMode: () => switchMode(context, konkur: false),
          )
        : const StudyHomeScreen();

    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => root,
        settings: const RouteSettings(name: '/study'),
      ),
    );
  }

  static Future<void> switchMode(
    BuildContext context, {
    required bool konkur,
  }) async {
    await StudySettingsRepository.instance.setKonkurMode(konkur);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    await open(context);
  }
}
