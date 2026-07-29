import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/core/ux/ritmo_sheet_scaffold.dart';
import 'package:ritmo/core/widgets/action/action_sheet_registry.dart';
import 'package:ritmo/core/widgets/action/action_sheet_result.dart';
import 'package:ritmo/core/widgets/action/sheet_actions.dart';

/// Five-zone unified Action Sheet presentation container.
class RitmoActionSheet extends StatefulWidget {
  final AgendaItem item;
  final ActionBody body;
  final SubmitAction primarySubmitAction;
  final List<SubmitAction> secondarySubmitActions;
  final List<HandoffAction> handoffActions;
  final List<SubmitAction> moreActions;

  const RitmoActionSheet({
    super.key,
    required this.item,
    required this.body,
    required this.primarySubmitAction,
    this.secondarySubmitActions = const [],
    this.handoffActions = const [],
    this.moreActions = const [],
  });

  /// Present the unified action sheet and return typed ActionSheetResult.
  static Future<ActionSheetResult?> present({
    required BuildContext context,
    required AgendaItem item,
    required ActionBody body,
    required SubmitAction primarySubmitAction,
    List<SubmitAction> secondarySubmitActions = const [],
    List<HandoffAction> handoffActions = const [],
    List<SubmitAction> moreActions = const [],
  }) {
    if (kDebugMode) {
      // Assert exactly single primary action rule
      assert(
        !secondarySubmitActions.any((a) => a.isDestructive),
        'Destructive actions must never be in secondary zone (Zone 4). Use Zone 5 (moreActions).',
      );
    }

    return RitmoSheetScaffold.present<ActionSheetResult>(
      context: context,
      semanticsLabel: 'پنجره کنش ${item.title}',
      builder: (context) => RitmoActionSheet(
        item: item,
        body: body,
        primarySubmitAction: primarySubmitAction,
        secondarySubmitActions: secondarySubmitActions,
        handoffActions: handoffActions,
        moreActions: moreActions,
      ),
    );
  }

  @override
  State<RitmoActionSheet> createState() => _RitmoActionSheetState();
}

class _RitmoActionSheetState extends State<RitmoActionSheet> {
  bool _busy = false;
  String? _activeActionId;
  String? _errorMessage;

  Future<void> _onSubmit(SubmitAction action) async {
    if (_busy) return;

    if (action.confirmationPrompt != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تأیید کنش'),
          content: Text(action.confirmationPrompt!),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('تأیید'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    if (mounted) {
      setState(() {
        _busy = true;
        _activeActionId = action.id;
        _errorMessage = null;
      });
    }

    RitmoHaptics.tap();

    try {
      final outcome = await action.onSubmit();
      if (!mounted) return;

      if (outcome.didWrite) {
        RitmoHaptics.success();
        Navigator.pop(context, ActionSheetSubmitted(outcome));
      } else {
        RitmoHaptics.error();
        setState(() {
          _errorMessage = outcome.errorMessage ?? 'خطایی در ثبت رخ داد.';
          _busy = false;
          _activeActionId = null;
        });
      }
    } catch (e, st) {
      debugPrint('[RitmoActionSheet] Exception during submission: $e\n$st');
      if (mounted) {
        RitmoHaptics.error();
        setState(() {
          _errorMessage = 'خطای غیرمنتظره: ${e.toString()}';
          _busy = false;
          _activeActionId = null;
        });
      }
    }
  }

  void _onHandoff(HandoffAction action) {
    if (_busy) return;
    RitmoHaptics.tap();
    Navigator.pop(context, ActionSheetHandoff(action.intent));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Zone 1: Identity Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getDomainIcon(widget.item.domain),
                color: colors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (widget.item.subtitle != null && widget.item.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.item.subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.border.withValues(alpha: 0.4)),
              ),
              child: Text(
                _getDomainName(widget.item.domain),
                style: TextStyle(
                  fontSize: 11,
                  color: colors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Zone 2: Domain-Specific Body
        widget.body,

        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.redAccent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Zone 3: Primary Action (Exactly ONE, full-width)
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: _busy ? null : () => _onSubmit(widget.primarySubmitAction),
          child: _busy && _activeActionId == widget.primarySubmitAction.id
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.primarySubmitAction.icon != null) ...[
                      Icon(widget.primarySubmitAction.icon, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.primarySubmitAction.label,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
        ),

        // Zone 4: Secondary Actions & Handoffs (Max 2 in a row)
        if (widget.secondarySubmitActions.isNotEmpty || widget.handoffActions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              ...widget.secondarySubmitActions.take(2).map((act) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.primary,
                          side: BorderSide(color: colors.primary.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _busy ? null : () => _onSubmit(act),
                        child: _busy && _activeActionId == act.id
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
                              )
                            : Text(
                                act.label,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  )),
              ...widget.handoffActions.take(2).map((hAct) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.textPrimary,
                          side: BorderSide(color: colors.border.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _busy ? null : () => _onHandoff(hAct),
                        child: Text(
                          hAct.label,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        ],

        // Zone 5: More (Collapsible destructives, skips, edits, details)
        if (widget.moreActions.isNotEmpty) ...[
          const SizedBox(height: 12),
          ExpansionTile(
            title: Text(
              'گزینه‌های بیشتر',
              style: TextStyle(fontSize: 12, color: colors.textSecondary, fontWeight: FontWeight.bold),
            ),
            shape: const Border(),
            childrenPadding: EdgeInsets.zero,
            children: widget.moreActions
                .map((mAct) => ListTile(
                      dense: true,
                      leading: Icon(
                        mAct.icon ?? CupertinoIcons.ellipsis,
                        color: mAct.isDestructive ? Colors.redAccent : colors.textSecondary,
                        size: 18,
                      ),
                      title: Text(
                        mAct.label,
                        style: TextStyle(
                          color: mAct.isDestructive ? Colors.redAccent : colors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                      onTap: _busy ? null : () => _onSubmit(mAct),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  IconData _getDomainIcon(AgendaDomain domain) {
    return switch (domain) {
      AgendaDomain.routine => CupertinoIcons.repeat,
      AgendaDomain.prayer => CupertinoIcons.sun_max,
      AgendaDomain.worship => CupertinoIcons.heart,
      AgendaDomain.worshipDebt => CupertinoIcons.book,
      AgendaDomain.sport => CupertinoIcons.sportscourt,
      AgendaDomain.goalStep => CupertinoIcons.flag,
      AgendaDomain.medicine => CupertinoIcons.bandage,
      AgendaDomain.konkur => CupertinoIcons.pencil,
      AgendaDomain.cycle => CupertinoIcons.drop,
    };
  }

  String _getDomainName(AgendaDomain domain) {
    return switch (domain) {
      AgendaDomain.routine => 'روتین',
      AgendaDomain.prayer => 'نماز',
      AgendaDomain.worship => 'مستحبات',
      AgendaDomain.worshipDebt => 'بدهی عبادی',
      AgendaDomain.sport => 'ورزش',
      AgendaDomain.goalStep => 'گام هدف',
      AgendaDomain.medicine => 'دارو',
      AgendaDomain.konkur => 'کنکور',
      AgendaDomain.cycle => 'چرخه',
    };
  }
}
