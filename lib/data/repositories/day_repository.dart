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

  Future<int> ensureDayExists({
    required DateTime date,
    required DailyPrayerTimes prayerTimes,
    required List<TaskTemplate> activeTemplates,
    Map<PrayerType, List<String>> orderPreferences = const {},
  }) async {
    final dateOnly = DateTime(date.year, date.month, date.day);

    final existing = await (db.select(db.days)
          ..where((t) => t.date.equals(dateOnly)))
        .getSingleOrNull();
    if (existing != null) return existing.id;

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
        final fixedTypes = fixedTasksForPrayer(prayerType);

        final preference = orderPreferences[prayerType];
        int orderOf(String key) {
          if (preference == null) {
            if (key == 'prayer') return 0;
            return 1 + fixedTypes.indexWhere((t) => t.name == key);
          }
          final index = preference.indexOf(key);
          return index == -1 ? preference.length : index;
        }

        final blockId = await db.into(db.prayerBlocks).insert(
              PrayerBlocksCompanion.insert(
                dayId: dayId,
                prayerType: prayerType,
                scheduledTime: scheduledTime,
                sortOrder: Value(orderOf('prayer')),
              ),
            );

        for (final fixedType in fixedTypes) {
          await db.into(db.fixedTasks).insert(
                FixedTasksCompanion.insert(
                  prayerBlockId: blockId,
                  taskType: fixedType,
                  sortOrder: Value(orderOf(fixedType.name)),
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
                  title: template.title,
                  sortOrder: Value(fixedTypes.length + 1),
                ),
              );
        }
      }

      return dayId;
    });
  }

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