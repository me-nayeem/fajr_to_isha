import '../../domain/consistency_calculator.dart';
import '../../domain/feedback_engine.dart';
import '../local/database.dart';
import 'day_aggregation.dart';

class FeedbackRepository {
  final AppDatabase db;

  FeedbackRepository(this.db);

  Future<FeedbackResult> generateCurrentFeedback({
    required DateTime asOf,
    int historyDays = 14,
  }) async {
    final aggregates = await aggregateDays(
      db,
      asOf: asOf,
      windowDays: historyDays,
    );

    final records = aggregates.map((a) {
      final input = DailyConsistencyInput(
        date: a.date,
        prayersCompleted: a.prayerCompletion.values.where((v) => v).length,
        fixedTasksCompleted: a.fixedTasksCompleted,
        fixedTasksScheduled: a.fixedTasksScheduled,
        userTasksCompleted: a.userTasksCompleted,
        userTasksScheduled: a.userTasksScheduled,
      );

      return DailyPrayerRecord(
        date: a.date,
        prayerCompletion: a.prayerCompletion,
        fixedTaskCompletion: a.fixedTaskCompletion,
        dayScore: calculateDayScore(input),
      );
    }).toList();

    return generateFeedback(history: records, asOf: asOf);
  }
}