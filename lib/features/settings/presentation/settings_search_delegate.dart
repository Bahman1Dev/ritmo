import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/localization/locale_repository.dart';
import 'package:ritmo/core/settings/settings_registry.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/theme/theme_repository.dart';
import 'package:ritmo/features/settings/presentation/groups/appearance_group_screen.dart';
import 'package:ritmo/features/settings/presentation/groups/assistant_privacy_group_screen.dart';
import 'package:ritmo/features/settings/presentation/groups/data_backup_group_screen.dart';
import 'package:ritmo/features/settings/presentation/groups/identity_group_screen.dart';
import 'package:ritmo/features/settings/presentation/groups/modules_group_screen.dart';
import 'package:ritmo/features/settings/presentation/groups/notifications_group_screen.dart';
import 'package:ritmo/features/settings/presentation/groups/security_group_screen.dart';

class SettingsSearchDelegate extends SearchDelegate<SettingDescriptor?> {
  SettingsSearchDelegate({
    required this.themeRepository,
    required this.localeRepository,
  });

  final ThemeRepository themeRepository;
  final LocaleRepository localeRepository;

  @override
  String? get searchFieldLabel => 'جست‌وجوی تنظیمات...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: colors.card,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: colors.textTertiary, fontSize: 15),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(CupertinoIcons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(CupertinoIcons.back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final colors = context.colors;
    final q = query.trim().toLowerCase();

    final results = SettingsRegistry.all.where((desc) {
      if (q.isEmpty) return true;
      if (desc.labelFa.toLowerCase().contains(q)) return true;
      if (desc.descriptionFa != null && desc.descriptionFa!.toLowerCase().contains(q)) return true;
      for (final t in desc.searchTerms) {
        if (t.toLowerCase().contains(q)) return true;
      }
      return false;
    }).toList();

    if (results.isEmpty) {
      return Center(
        child: Text(
          'موردی برای «$query» یافت نشد.',
          style: TextStyle(color: colors.textSecondary, fontSize: 14),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      separatorBuilder: (_, __) => Divider(color: colors.border),
      itemBuilder: (context, index) {
        final desc = results[index];
        return ListTile(
          title: Text(
            desc.labelFa,
            style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary),
          ),
          subtitle: desc.descriptionFa != null
              ? Text(desc.descriptionFa!, style: TextStyle(fontSize: 12, color: colors.textSecondary))
              : null,
          trailing: Text(
            _getGroupName(desc.group),
            style: TextStyle(fontSize: 11, color: colors.primary, fontWeight: FontWeight.bold),
          ),
          onTap: () {
            close(context, desc);
            _navigateToGroup(context, desc.group);
          },
        );
      },
    );
  }

  String _getGroupName(SettingsGroup group) {
    switch (group) {
      case SettingsGroup.identity:
        return 'حساب و هویت';
      case SettingsGroup.modules:
        return 'ماژول‌ها';
      case SettingsGroup.notifications:
        return 'اعلان‌ها';
      case SettingsGroup.appearance:
        return 'ظاهر و زبان';
      case SettingsGroup.assistant:
        return 'دستیار';
      case SettingsGroup.dataBackup:
        return 'داده و پشتیبان';
      case SettingsGroup.security:
        return 'امنیت';
    }
  }

  void _navigateToGroup(BuildContext context, SettingsGroup group) {
    Widget page;
    switch (group) {
      case SettingsGroup.identity:
        page = const IdentityGroupScreen();
        break;
      case SettingsGroup.modules:
        page = const ModulesGroupScreen();
        break;
      case SettingsGroup.notifications:
        page = const NotificationsGroupScreen();
        break;
      case SettingsGroup.appearance:
        page = AppearanceGroupScreen(
          themeRepository: themeRepository,
          localeRepository: localeRepository,
        );
        break;
      case SettingsGroup.assistant:
        page = const AssistantPrivacyGroupScreen();
        break;
      case SettingsGroup.dataBackup:
        page = const DataBackupGroupScreen();
        break;
      case SettingsGroup.security:
        page = const SecurityGroupScreen();
        break;
    }

    Navigator.push(context, CupertinoPageRoute(builder: (_) => page));
  }
}
