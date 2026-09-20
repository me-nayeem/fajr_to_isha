import '../local/database.dart';
import '../local/tables.dart';

class DayAggregate {
  final DateTime date;
  final Map<PrayerType, bool> prayerCompletion;
  final Map<FixedTaskType, bool> fixedTaskCompletion;
  final int fixedTasksCompleted;
  final int fixedTasksScheduled;
  final int userTasksCompleted;
  final int userTasksScheduled;

  const DayAggregate({
    required this.date,
    required this.prayerCompletion,
    required this.fixedTaskCompletion,
    required this.fixedTasksCompleted,
    required this.fixedTasksScheduled,
    required this.userTasksCompleted,
    required this.userTasksScheduled,
  });
}

Future<List<DayAggregate>> aggregateDays(
  AppDatabase db, {
  required DateTime asOf,
  required int windowDays,
}) async {
  final cutoff = asOf.subtract(Duration(days: windowDays));

  final allDays = await db.select(db.days).get();
  final days = allDays
      .where((d) => !d.date.isBefore(cutoff) && !d.date.isAfter(asOf))
      .toList();

  final result = <DayAggregate>[];

  for (final day in days) {
    final blocks = await (db.select(db.prayerBlocks)
          ..where((t) => t.dayId.equals(day.id)))
        .get();

    final prayerCompletion = <PrayerType, bool>{};
    final fixedTaskCompletion = <FixedTaskType, bool>{};
    var fixedCompleted = 0;
    var fixedScheduled = 0;
    var userCompleted = 0;
    var userScheduled = 0;

    for (final block in blocks) {
      prayerCompletion[block.prayerType] = block.prayerCompleted;

      final fixedTasks = await (db.select(db.fixedTasks)
            ..where((t) => t.prayerBlockId.equals(block.id)))
          .get();
      fixedScheduled += fixedTasks.length;
      fixedCompleted += fixedTasks.where((t) => t.completed).length;
      for (final task in fixedTasks) {
        fixedTaskCompletion[task.taskType] = task.completed;
      }

      final userTasks = await (db.select(db.userTaskInstances)
            ..where((t) => t.prayerBlockId.equals(block.id)))
          .get();
      userScheduled += userTasks.length;
      userCompleted += userTasks.where((t) => t.completed).length;
    }

    result.add(DayAggregate(
      date: day.date,
      prayerCompletion: prayerCompletion,
      fixedTaskCompletion: fixedTaskCompletion,
      fixedTasksCompleted: fixedCompleted,
      fixedTasksScheduled: fixedScheduled,
      userTasksCompleted: userCompleted,
      userTasksScheduled: userScheduled,
    ));
  }

  return result;
}