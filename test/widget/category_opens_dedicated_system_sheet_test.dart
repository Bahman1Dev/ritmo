import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/features/routines/presentation/planner_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Category Opens Dedicated System Sheet Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Tapping Worship delegates to openWorshipSheet with prefill', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                var worshipSheetOpened = false;

                final controller = PlannerController(
                  onSaved: () {},
                  onPageChanged: (_) {},
                );
                controller.moduleReligionEnabled = true;

                controller.title = 'نماز شب';
                controller.selectedTime = const TimeOfDay(hour: 23, minute: 30);
                controller.setWorshipSheetOpener(({prefill}) {
                  worshipSheetOpened = true;
                  expect(prefill?['title'], equals('نماز شب'));
                });

                controller.selectCategory(Category.religious, context);
                expect(worshipSheetOpened, isTrue);

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('Tapping Medical delegates to openMedicalSheet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                var medicalSheetOpened = false;

                final controller = PlannerController(
                  onSaved: () {},
                  onPageChanged: (_) {},
                );
                controller.moduleMedicineEnabled = true;

                controller.title = 'ویتامین c';
                controller.setMedicalSheetOpener(([data]) {
                  medicalSheetOpened = true;
                });

                controller.selectCategory(Category.medical, context);
                expect(medicalSheetOpened, isTrue);

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('Tapping Course delegates to openCourseSheet with initialValues', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                var courseSheetOpened = false;

                final controller = PlannerController(
                  onSaved: () {},
                  onPageChanged: (_) {},
                );
                controller.moduleCoursesEnabled = true;

                controller.title = 'دوره پایتون';
                controller.setCourseSheetOpener(({initialValues}) {
                  courseSheetOpened = true;
                  expect(initialValues?['title'], equals('دوره پایتون'));
                });

                controller.selectCategory(Category.learning, context);
                expect(courseSheetOpened, isTrue);

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('Tapping Goal delegates to openGoalSheet with templateData', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                var goalSheetOpened = false;

                final controller = PlannerController(
                  onSaved: () {},
                  onPageChanged: (_) {},
                );
                controller.moduleGoalsEnabled = true;

                controller.title = 'کاهش وزن';
                controller.setGoalSheetOpener(({templateData}) {
                  goalSheetOpened = true;
                  expect(templateData?['title'], equals('کاهش وزن'));
                });

                controller.selectCategory(Category.custom, context);
                expect(goalSheetOpened, isTrue);

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('Tapping Sports delegates to openSportsLogSheet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                var sportsSheetOpened = false;

                final controller = PlannerController(
                  onSaved: () {},
                  onPageChanged: (_) {},
                );
                controller.moduleSportsEnabled = true;

                controller.title = 'تمرین پا';
                controller.setSportsLogSheetOpener(({durationMinutes}) {
                  sportsSheetOpened = true;
                });

                controller.selectCategory(Category.fitness, context);
                expect(sportsSheetOpened, isTrue);

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
    });
  });
}
