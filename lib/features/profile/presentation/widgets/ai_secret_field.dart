import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/theme/ritmo_colors.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/widgets/ritmo/ritmo_dialog.dart';

class AiSecretField extends StatefulWidget {
  const AiSecretField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.errorText,
    this.onChanged,
    this.onDelete,
    this.hasStoredKey = false,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final Future<void> Function()? onDelete;
  final bool hasStoredKey;

  @override
  State<AiSecretField> createState() => _AiSecretFieldState();
}

class _AiSecretFieldState extends State<AiSecretField> {
  bool _obscure = true;

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isNotEmpty) {
      widget.controller.text = text;
      widget.onChanged?.call(text);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => RitmoDialog(
        title: 'حذف کلید ذخیره‌شده',
        content: 'آیا از حذف این کلید از حافظهٔ امن اطمینان دارید؟',
        confirmLabel: 'حذف',
        cancelLabel: 'انصراف',
        isDestructive: true,
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );

    if (confirmed == true && widget.onDelete != null) {
      await widget.onDelete!();
      widget.controller.clear();
      widget.onChanged?.call('');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasValue = widget.controller.text.isNotEmpty || widget.hasStoredKey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          obscureText: _obscure,
          onChanged: widget.onChanged,
          style: TextStyle(
            fontSize: 15,
            color: colors.textPrimary,
            fontFamily: 'Vazirmatn',
          ),
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              fontFamily: 'Vazirmatn',
            ),
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: colors.textTertiary,
              fontSize: 13,
              fontFamily: 'Vazirmatn',
            ),
            errorText: widget.errorText,
            errorStyle: TextStyle(
              color: colors.error,
              fontSize: 11,
              fontFamily: 'Vazirmatn',
            ),
            prefixIcon: Icon(Icons.key_rounded, color: colors.primary, size: 20),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    _obscure ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                    color: colors.textSecondary,
                    size: 20,
                  ),
                  tooltip: _obscure ? 'نمایش کلید' : 'مخفی‌سازی کلید',
                  onPressed: () {
                    setState(() {
                      _obscure = !_obscure;
                    });
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.content_paste_rounded,
                    color: colors.primary,
                    size: 20,
                  ),
                  tooltip: 'جای‌گذاری از کلیپ‌بورد',
                  onPressed: _pasteFromClipboard,
                ),
              ],
            ),
            filled: true,
            fillColor: colors.surfaceSunken,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(RitmoRadius.field),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(RitmoRadius.field),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(RitmoRadius.field),
              borderSide: BorderSide(color: colors.primary, width: 1.5),
            ),
          ),
        ),
        if (hasValue && widget.onDelete != null) ...[
          const SizedBox(height: RitmoSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _confirmDelete,
              icon: Icon(Icons.delete_outline_rounded, color: colors.error, size: 16),
              label: Text(
                'حذف کلید از حافظهٔ امن',
                style: TextStyle(
                  color: colors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
