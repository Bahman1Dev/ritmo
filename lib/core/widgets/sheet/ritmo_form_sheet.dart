import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/ux/ritmo_sheet_scaffold.dart';

class FormStep {
  final String title;
  final Widget content;
  final bool Function()? validate;

  const FormStep({
    required this.title,
    required this.content,
    this.validate,
  });
}

/// Generic multi-step form sheet shell.
class RitmoFormSheet extends StatefulWidget {
  final String formTitle;
  final List<FormStep> steps;
  final Future<bool> Function() onComplete;

  const RitmoFormSheet({
    super.key,
    required this.formTitle,
    required this.steps,
    required this.onComplete,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String formTitle,
    required List<FormStep> steps,
    required Future<bool> Function() onComplete,
  }) {
    return RitmoSheetScaffold.present<bool>(
      context: context,
      semanticsLabel: 'فرم $formTitle',
      builder: (context) => RitmoFormSheet(
        formTitle: formTitle,
        steps: steps,
        onComplete: onComplete,
      ),
    );
  }

  @override
  State<RitmoFormSheet> createState() => _RitmoFormSheetState();
}

class _RitmoFormSheetState extends State<RitmoFormSheet> {
  int _currentStepIndex = 0;
  bool _busy = false;
  String? _errorMessage;

  void _onNext() async {
    final currentStep = widget.steps[_currentStepIndex];
    if (currentStep.validate != null && !currentStep.validate!()) {
      return;
    }

    if (_currentStepIndex < widget.steps.length - 1) {
      setState(() => _currentStepIndex++);
    } else {
      // Last step: Save
      setState(() {
        _busy = true;
        _errorMessage = null;
      });
      try {
        final success = await widget.onComplete();
        if (mounted) {
          if (success) {
            Navigator.pop(context, true);
          } else {
            setState(() {
              _errorMessage = 'خطا در ثبت فرم.';
              _busy = false;
            });
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = e.toString();
            _busy = false;
          });
        }
      }
    }
  }

  void _onPrevious() {
    if (_currentStepIndex > 0) {
      setState(() => _currentStepIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final totalSteps = widget.steps.length;
    final currentStep = widget.steps[_currentStepIndex];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.formTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),

        if (totalSteps > 1) ...[
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (_currentStepIndex + 1) / totalSteps,
            backgroundColor: colors.border.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
          const SizedBox(height: 6),
          Text(
            'گام ${_currentStepIndex + 1} از $totalSteps: ${currentStep.title}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: colors.textSecondary),
          ),
        ],

        const SizedBox(height: 16),

        currentStep.content,

        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],

        const SizedBox(height: 20),

        Row(
          children: [
            if (_currentStepIndex > 0) ...[
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _busy ? null : _onPrevious,
                  child: const Text('قبلی'),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _busy ? null : _onNext,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_currentStepIndex == totalSteps - 1 ? 'ثبت نهایی' : 'بعدی'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
