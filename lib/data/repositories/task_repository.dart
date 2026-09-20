import 'package:drift/drift.dart';

import '../../domain/daily_view_data.dart';
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

  Future<int> _nextSortOrder(int prayerBlockId) async {
    final block = await (db.select(db.prayerBlocks)
          ..where((t) => t.id.equals(prayerBlockId)))
        .getSingle();
    final fixedTasks = await (db.select(db.fixedTasks)
          ..where((t) => t.prayerBlockId.equals(prayerBlockId)))
        .get();
    final userTasks = await (db.select(db.userTaskInstances)
          ..where((t) => t.prayerBlockId.equals(prayerBlockId)))
        .get();

    var maxOrder = block.sortOrder;
    for (final task in fixedTasks) {
      if (task.sortOrder > maxOrder) maxOrder = task.sortOrder;
    }
    for (final task in userTasks) {
      if (task.sortOrder > maxOrder) maxOrder = task.sortOrder;
    }
    return maxOrder + 1;
  }

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
      final sortOrder = await _nextSortOrder(prayerBlockId);
      await db.into(db.userTaskInstances).insert(
            UserTaskInstancesCompanion.insert(
              templateId: Value(templateId),
              dayId: dayId,
              prayerBlockId: prayerBlockId,
              title: title,
              sortOrder: Value(sortOrder),
            ),
          );
    }
  }

  Future<void> reorderBlockItems(List<TaskItem> orderedItems) async {
    await db.transaction(() async {
      for (var i = 0; i < orderedItems.length; i++) {
        final item = orderedItems[i];
        switch (item.kind) {
          case TaskItemKind.prayer:
            await (db.update(db.prayerBlocks)
                  ..where((t) => t.id.equals(item.prayerBlock!.id)))
                .write(PrayerBlocksCompanion(sortOrder: Value(i)));
          case TaskItemKind.fixed:
            await (db.update(db.fixedTasks)
                  ..where((t) => t.id.equals(item.fixedTask!.id)))
                .write(FixedTasksCompanion(sortOrder: Value(i)));
          case TaskItemKind.user:
            await (db.update(db.userTaskInstances)
                  ..where((t) => t.id.equals(item.userTask!.id)))
                .write(UserTaskInstancesCompanion(sortOrder: Value(i)));
        }
      }
    });
  }
}