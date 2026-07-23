enum Feeling { easy, good, hard }

class OnboardingUiState {

  OnboardingUiState({
    this.currentStep = 1,
    this.totalSteps = 7,
    this.goal,
    this.experienceLevel,
    this.trainingLocation,
    this.availableEquipment = const [],
    this.daysPerWeek = 3,
    this.focusAreas = const [],
    this.limitationNote = '',
    this.isGeneratingPlan = false,
  });
  final int currentStep;
  final int totalSteps;
  final String? goal;
  final String? experienceLevel;
  final String? trainingLocation;
  final List<String> availableEquipment;
  final int daysPerWeek;
  final List<String> focusAreas;
  final String limitationNote;
  final bool isGeneratingPlan;
}

sealed class HomeUiState {}

class HomeLoading extends HomeUiState {}

class HomeRestDay extends HomeUiState {
  HomeRestDay({this.suggestion});
  final String? suggestion;
}

class HomeWorkoutReady extends HomeUiState {

  HomeWorkoutReady({
    required this.dayName,
    required this.exerciseCount,
    required this.estimatedMinutes,
    required this.continuity,
    this.aiSuggestion,
    required this.weekTimeline,
  });
  final String dayName;
  final int exerciseCount;
  final int estimatedMinutes;
  final List<bool> continuity;
  final String? aiSuggestion;
  final List<String> weekTimeline;
}

class ExerciseChecklistEntry {

  ExerciseChecklistEntry({
    required this.exerciseId,
    required this.name,
    required this.referenceSets,
    required this.referenceReps,
    this.referenceWeight,
    required this.status,
    this.feeling,
  });
  final String exerciseId;
  final String name;
  final int referenceSets;
  final int referenceReps;
  final double? referenceWeight;
  final String status; // 'DONE', 'CURRENT', 'UPCOMING'
  final Feeling? feeling;
}

class WorkoutSessionUiState {

  WorkoutSessionUiState({
    required this.dayId,
    required this.exercises,
    required this.currentExerciseIndex,
    this.isShowingRestBanner = false,
    this.isShowingFeelingSheet = false,
  });
  final String dayId;
  final List<ExerciseChecklistEntry> exercises;
  final int currentExerciseIndex;
  final bool isShowingRestBanner;
  final bool isShowingFeelingSheet;
}

sealed class ChatMessage {}

class TextMessage extends ChatMessage {
  TextMessage({required this.content, required this.fromUser});
  final String content;
  final bool fromUser;
}

class ActionableSuggestionMessage extends ChatMessage {

  ActionableSuggestionMessage({
    required this.title,
    required this.description,
    required this.actionLabel,
    this.changeData,
  });
  final String title;
  final String description;
  final String actionLabel;
  final Map<String, dynamic>? changeData;
}

class SafetyWarningMessage extends ChatMessage {
  SafetyWarningMessage({required this.content});
  final String content;
}

class AiCoachUiState {

  AiCoachUiState({
    required this.messages,
    required this.quickReplies,
    required this.isAiTyping,
  });
  final List<ChatMessage> messages;
  final List<String> quickReplies;
  final bool isAiTyping;
}
