import 'package:flutter/material.dart';
import 'package:ritmo/core/localization/locale_repository.dart';
import 'package:ritmo/core/theme/theme_repository.dart';
import 'package:ritmo/features/settings/presentation/settings_screen.dart';

/// [ProfileScreen] delegates completely to [SettingsScreen] (Prompt 058).
/// Maintains backward compatibility with previous constructor signatures.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.onLogout,
    required this.themeRepository,
    required this.localeRepository,
  });

  final VoidCallback onLogout;
  final ThemeRepository themeRepository;
  final LocaleRepository localeRepository;

  @override
  Widget build(BuildContext context) {
    return SettingsScreen(
      onFactoryReset: onLogout,
      themeRepository: themeRepository,
      localeRepository: localeRepository,
    );
  }
}
