import 'package:flutter/foundation.dart';
import 'package:ritmo/core/ai/ai_gateway.dart';

class GoalBreakdownResult {
  GoalBreakdownResult({
    required this.smartTitle,
    required this.smartDesc,
    required this.potentialRisks,
    required this.contingencyPlan,
    required this.subGoals,
    required this.directSteps,
  });

  final String smartTitle;
  final String smartDesc;
  final List<String> potentialRisks;
  final String contingencyPlan;
  final List<Map<String, dynamic>> subGoals;
  final List<Map<String, dynamic>> directSteps;
}

class GoalBreakdownService {
  GoalBreakdownService._();

  static Future<GoalBreakdownResult?> generateBreakdown({
    required String title,
    required String description,
    required String goalType,
    String? successCriterion,
    int? weeklyCapacityHours,
    String? mainObstacle,
    List<String>? userRoutines,
  }) async {
    try {
      final map = await AIGateway.instance.breakDownGoal(
        goalTitle: title,
        goalDescription: description,
        goalType: goalType,
        userRoutines: userRoutines,
      );

      return GoalBreakdownResult(
        smartTitle: map['smartTitle'] as String? ?? title,
        smartDesc: map['smartDesc'] as String? ?? description,
        potentialRisks: (map['potentialRisks'] as List<dynamic>?)?.cast<String>() ?? [],
        contingencyPlan: map['contingencyPlan'] as String? ?? '',
        subGoals: (map['subGoals'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
        directSteps: (map['steps'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
      );
    } catch (e) {
      debugPrint('Error generating goal breakdown: $e');
      return null;
    }
  }
}
