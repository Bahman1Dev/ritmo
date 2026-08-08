import 'package:ritmo/core/domain/commands/ritmo_command.dart';

class PlanStep {
  const PlanStep({
    required this.commandId,
    required this.payload,
    this.note,
  });

  final String commandId;
  final Map<String, dynamic> payload;
  final String? note;

  factory PlanStep.fromJson(Map<String, dynamic> json) {
    return PlanStep(
      commandId: json['commandId'] as String? ?? json['command'] as String? ?? '',
      payload: (json['payload'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commandId': commandId,
      'payload': payload,
      'note': note,
    };
  }
}

class CommandPlan {
  const CommandPlan({
    required this.id,
    required this.titleFa,
    required this.steps,
  });

  final String id;
  final String titleFa;
  final List<PlanStep> steps;

  factory CommandPlan.fromJson(Map<String, dynamic> json) {
    final rawSteps = json['steps'] as List? ?? [];
    return CommandPlan(
      id: json['id'] as String? ?? '',
      titleFa: json['titleFa'] as String? ?? json['title'] as String? ?? 'برنامه دستیار',
      steps: rawSteps.map((s) => PlanStep.fromJson(s as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titleFa': titleFa,
      'steps': steps.map((s) => s.toJson()).toList(),
    };
  }
}

enum DiffKind {
  create,
  update,
  delete,
  navigate,
  noop,
}

class PlanDiff {
  const PlanDiff({
    required this.kind,
    required this.entityLabelFa,
    this.beforeFa,
    this.afterFa,
    this.warningFa,
  });

  final DiffKind kind;
  final String entityLabelFa;
  final String? beforeFa;
  final String? afterFa;
  final String? warningFa;

  Map<String, dynamic> toJson() {
    return {
      'kind': kind.name,
      'entityLabelFa': entityLabelFa,
      'beforeFa': beforeFa,
      'afterFa': afterFa,
      'warningFa': warningFa,
    };
  }
}

class PlanPreview {
  const PlanPreview({
    required this.diffs,
    required this.blockers,
    required this.needsBiometric,
  });

  final List<PlanDiff> diffs;
  final List<String> blockers;
  final bool needsBiometric;

  Map<String, dynamic> toJson() {
    return {
      'diffs': diffs.map((d) => d.toJson()).toList(),
      'blockers': blockers,
      'needsBiometric': needsBiometric,
    };
  }
}

class PlanResult {
  PlanResult({
    required this.success,
    required this.planId,
    required this.results,
    this.errorMessage,
  });

  final bool success;
  final String planId;
  final List<CommandResult> results;
  final String? errorMessage;
}
