import 'package:drift/drift.dart';

import '../../domain/daily_view_data.dart';
import '../../domain/fixed_task_rules.dart';
import '../../domain/task_recurrence_rules.dart';
import '../local/database.dart';
import '../local/tables.dart';
import '../services/prayer_time_service.dart';

class DayRepository {
  final AppDatabase db;

  DayRepository(this.db);

  /// Returns the id of the Day for [date] — creating it (with all its
  /// prayer blocks, fixed tasks, and applicable recurring user tasks) if
  /// it doesn't exist yet. Safe to call repeatedly for the same date;
  /// it will never duplicate data.
  ///
  /// Note: this function does NOT resolve prayer times or fetch templates
  /// itself — the caller provides [prayerTimes] (already resolved via
  /// PrayerTimeService or manual settings) and [activeTemplates] (already
  /// queried from the database). Keeping this function focused purely on
  /// "given these inputs, generate the day's rows" makes it simple to
  /// test without needing to mock location/prayer-time services.
  Future<int> ensureDayExists({
    required DateTime date,
    required DailyPrayerTimes prayerTimes,
    required List<TaskTemplate> activeTemplates,
  }) async {
    final dateOnly = DateTime(date.year, date.month, date.day);

    final existing = await (db.select(db.days)
          ..where((t) => t.date.equals(dateOnly)))
        .getSingleOrNull();
    if (existing != null) return existing.id;

    // Wrapped in a transaction: if anything fails partway through (a
    // crash, a bug), we end up with either a fully-formed day or no day
    // at all — never a half-created one with missing blocks.
    return db.transaction(() async {
      final dayId = await db.into(db.days).insert(
            DaysCompanion.insert(date: dateOnly),
          );

      final scheduledTimeFor = <PrayerType, DateTime>{
        PrayerType.fajr: prayerTimes.fajr,
        PrayerType.dhuhr: prayerTimes.dhuhr,
        PrayerType.asr: prayerTimes.asr,
        PrayerType.maghrib: prayerTimes.maghrib,
        PrayerType.isha: prayerTimes.isha,
      };

      for (final entry in scheduledTimeFor.entries) {
        final prayerType = entry.key;
        final scheduledTime = entry.value;

        final blockId = await db.into(db.prayerBlocks).insert(
              PrayerBlocksCompanion.insert(
                dayId: dayId,
                prayerType: prayerType,
                scheduledTime: scheduledTime,
              ),
            );

        for (final fixedType in fixedTasksForPrayer(prayerType)) {
          await db.into(db.fixedTasks).insert(
                FixedTasksCompanion.insert(
                  prayerBlockId: blockId,
                  taskType: fixedType,
                ),
              );
        }

        for (final template in activeTemplates) {
          if (template.prayerBlockType != prayerType) continue;

          final applies = templateAppliesToDate(
            recurrenceType: template.recurrenceType,
            date: dateOnly,
            specificDate: template.specificDate,
            startDate: template.startDate,
            endDate: template.endDate,
            weekdays: template.weekdays,
          );
          if (!applies) continue;

          await db.into(db.userTaskInstances).insert(
                UserTaskInstancesCompanion.insert(
                  templateId: Value(template.id),
                  dayId: dayId,
                  prayerBlockId: blockId,
                  // Copied now, not referenced live — protects history
                  // if the template is renamed/deleted later.
                  title: template.title,
                ),
              );
        }
      }

      return dayId;
    });
  }

  /// Loads the full day — all 5 blocks, each with its fixed tasks and
  /// user task instances — into one UI-ready shape.
  Future<DailyViewData> loadDayView(int dayId) async {
    final day =
        await (db.select(db.days)..where((t) => t.id.equals(dayId)))
            .getSingle();
    final blocks = await (db.select(db.prayerBlocks)
          ..where((t) => t.dayId.equals(dayId)))
        .get();

    final blocksByType = <PrayerType, BlockView>{};
    for (final block in blocks) {
      final fixedTasks = await (db.select(db.fixedTasks)
            ..where((t) => t.prayerBlockId.equals(block.id)))
          .get();
      final userTasks = await (db.select(db.userTaskInstances)
            ..where((t) => t.prayerBlockId.equals(block.id)))
          .get();

      blocksByType[block.prayerType] = BlockView(
        block: block,
        fixedTasks: fixedTasks,
        userTasks: userTasks,
      );
    }

    return DailyViewData(day: day, blocksByType: blocksByType);
  }
}