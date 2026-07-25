import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/completion/completion_outcome.dart';

void main() {
  testWidgets('CompletionOutcome failure yields error feedback', (WidgetTester tester) async {
    final outcome = CompletionOutcome.failure('خطای تست ثبت');

    expect(outcome.didWrite, isFalse);
    expect(outcome.errorMessage, equals('خطای تست ثبت'));
  });
}
