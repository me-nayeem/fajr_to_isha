import 'package:drift/drift.dart';

import '../../domain/task_recurrence_rules.dart';
import '../local/database.dart';
import '../local/tables.dart';

class TaskRepository {
  final AppDatabase db;

  TaskRepository(this.db);

  Future<List<TaskTemplate>> getActiveTemplates() {
    return (db.select(db.taskTemplates)..where((t) => t.active.equals(true)))
        .get();
  }

  Future<void> setPrayerCompleted(int prayerBlockId, bool completed) async {
    await (db.update(db.prayerBlocks)
          ..where((t) => t.id.equals(prayerBlockId)))
        .write(
      PrayerBlocksCompanion(
        prayerCompleted: Value(completed),
        completedAt: Value(completed ? DateTime.now() : null),
      ),
    );
  }

  Future<void> setFixedTaskCompleted(int fixedTaskId, bool completed) async {
    await (db.update(db.fixedTasks)..where((t) => t.id.equals(fixedTaskId)))
        .write(
      FixedTasksCompanion(
        completed: Value(completed),
        completedAt: Value(completed ? DateTime.now() : null),
      ),
    );
  }

  Future<void> setUserTaskCompleted(int instanceId, bool completed) async {
    await (db.update(db.userTaskInstances)
          ..where((t) => t.id.equals(instanceId)))
        .write(
      UserTaskInstancesCompanion(
        completed: Value(completed),
        completedAt: Value(completed ? DateTime.now() : null),
      ),
    );
  }

  /// Creates a new task template (once / daily / date range / custom
  /// weekdays), and — if it applies to [forDate] — immediately generates
  /// that day's instance too. This second step matters: [forDate]'s Day
  /// row was already generated before this template existed, so without
  /// this, a task added "for today" wouldn't actually show up today.
  Future<void> addUserTask({
    required String title,
    required PrayerType prayerBlockType,
    required RecurrenceType recurrenceType,
    required DateTime forDate,
    required int dayId,
    required int prayerBlockId,
    DateTime? specificDate,
    DateTime? startDate,
    DateTime? endDate,
    String? weekdays,
  }) async {
    final templateId = await db.into(db.taskTemplates).insert(
          TaskTemplatesCompanion.insert(
            title: title,
            prayerBlockType: prayerBlockType,
            recurrenceType: recurrenceType,
            specificDate: Value(specificDate),
            startDate: Value(startDate),
            endDate: Value(endDate),
            weekdays: Value(weekdays),
          ),
        );

    final appliesToday = templateAppliesToDate(
      recurrenceType: recurrenceType,
      date: forDate,
      specificDate: specificDate,
      startDate: startDate,
      endDate: endDate,
      weekdays: weekdays,
    );

    if (appliesToday) {
      await db.into(db.userTaskInstances).insert(
            UserTaskInstancesCompanion.insert(
              templateId: Value(templateId),
              dayId: dayId,
              prayerBlockId: prayerBlockId,
              title: title,
            ),
          );
    }
  }
}