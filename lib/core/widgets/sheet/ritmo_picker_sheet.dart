import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/ux/ritmo_sheet_scaffold.dart';

class PickerOption<T> {
  final String label;
  final String? subtitle;
  final IconData? icon;
  final T value;

  const PickerOption({
    required this.label,
    this.subtitle,
    this.icon,
    required this.value,
  });
}

/// Generic item selector sheet.
///
/// IRON RULE: A picker NEVER writes to the database or gateway directly.
/// It only allows selection and returns the chosen item or null.
class RitmoPickerSheet<T> extends StatefulWidget {
  final String title;
  final List<PickerOption<T>> options;
  final T? initialValue;
  final bool enableSearch;

  const RitmoPickerSheet({
    super.key,
    required this.title,
    required this.options,
    this.initialValue,
    this.enableSearch = false,
  });

  /// Present picker and return selected value or null.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<PickerOption<T>> options,
    T? initialValue,
    bool enableSearch = false,
  }) {
    return RitmoSheetScaffold.present<T>(
      context: context,
      semanticsLabel: 'انتخابگر $title',
      builder: (context) => RitmoPickerSheet<T>(
        title: title,
        options: options,
        initialValue: initialValue,
        enableSearch: enableSearch,
      ),
    );
  }

  @override
  State<RitmoPickerSheet<T>> createState() => _RitmoPickerSheetState<T>();
}

class _RitmoPickerSheetState<T> extends State<RitmoPickerSheet<T>> {
  late List<PickerOption<T>> _filteredOptions;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredOptions = widget.options;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredOptions = widget.options;
      } else {
        _filteredOptions = widget.options
            .where((opt) =>
                opt.label.toLowerCase().contains(query) ||
                (opt.subtitle != null && opt.subtitle!.toLowerCase().contains(query)))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),

        if (widget.enableSearch) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'جست‌وجو...',
              prefixIcon: const Icon(CupertinoIcons.search, size: 18),
              filled: true,
              fillColor: colors.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),

        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _filteredOptions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final opt = _filteredOptions[index];
              final isSelected = widget.initialValue == opt.value;

              return ListTile(
                onTap: () => Navigator.pop(context, opt.value),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: isSelected ? colors.primary.withValues(alpha: 0.12) : colors.surface,
                leading: opt.icon != null
                    ? Icon(opt.icon, color: isSelected ? colors.primary : colors.textSecondary)
                    : null,
                title: Text(
                  opt.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? colors.primary : colors.textPrimary,
                  ),
                ),
                subtitle: opt.subtitle != null
                    ? Text(
                        opt.subtitle!,
                        style: TextStyle(fontSize: 11, color: colors.textSecondary),
                      )
                    : null,
                trailing: isSelected
                    ? Icon(CupertinoIcons.check_mark, color: colors.primary, size: 18)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}
