import 'package:ritmo/core/domain/engines/ritmo_engine_bus.dart';

enum DataMaturity {
  notEnoughData,
  partialData,
  fullData,
}

class DataMaturityEngineInput {
  DataMaturityEngineInput({
    required this.daysOfData,
    required this.completionCount,
    required this.energyLogsCount,
  });
  final int daysOfData;
  final int completionCount;
  final int energyLogsCount;
}

class DataMaturityEngine implements CachedEngine<DataMaturityEngineInput, DataMaturity> {
  @override
  Future<DataMaturity> calculate(DataMaturityEngineInput input) async {
    return evaluate(
      daysOfData: input.daysOfData,
      completionCount: input.completionCount,
      energyLogsCount: input.energyLogsCount,
    );
  }

  @override
  void invalidate() {}

  @override
  bool canRun(DataMaturityEngineInput input) => true;

  @override
  List<Type> dependencies() => [];

  static DataMaturity evaluate({
    required int daysOfData,
    required int completionCount,
    required int energyLogsCount,
  }) {
    if (daysOfData < 14) {
      return DataMaturity.notEnoughData;
    }
    if (daysOfData < 30) {
      return DataMaturity.partialData;
    }
    return DataMaturity.fullData;
  }

  /// Ensures there is enough data for a weekly trend comparison (e.g. this week vs last week).
  static bool hasEnoughDataForWeeklyTrend(int daysOfData) {
    return daysOfData >= 7;
  }

  /// Ensures there is enough data for long-term monthly comparisons.
  static bool hasEnoughDataForMonthlyComparison(int daysOfData) {
    return daysOfData >= 60;
  }

  /// Ensures there are enough cycles logged to make a reliable hormonal prediction.
  static bool hasEnoughDataForCyclePrediction(int loggedCyclesCount) {
    return loggedCyclesCount >= 2;
  }
}
