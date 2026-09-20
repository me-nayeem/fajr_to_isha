import '../../domain/consistency_calculator.dart';
import '../local/database.dart';
import 'day_aggregation.dart';

class ConsistencyRepository {
  final AppDatabase db;

  ConsistencyRepository(this.db);

  Future<double> calculateCurrentConsistency({
    required DateTime asOf,
    int windowDays = 30,
  }) async {
    final aggregates = await aggregateDays(
      db,
      asOf: asOf,
      windowDays: windowDays,
    );

    final inputs = aggregates
        .map((a) => DailyConsistencyInput(
              date: a.date,
              prayersCompleted:
                  a.prayerCompletion.values.where((v) => v).length,
              fixedTasksCompleted: a.fixedTasksCompleted,
              fixedTasksScheduled: a.fixedTasksScheduled,
              userTasksCompleted: a.userTasksCompleted,
              userTasksScheduled: a.userTasksScheduled,
            ))
        .toList();

    return calculateConsistencyValue(
      days: inputs,
      asOf: asOf,
      windowDays: windowDays,
    );
  }
}