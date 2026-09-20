import 'package:drift/native.dart';
import 'package:fajr_to_isha/data/local/database.dart';
import 'package:fajr_to_isha/data/local/tables.dart';
import 'package:fajr_to_isha/data/repositories/consistency_repository.dart';
import 'package:fajr_to_isha/data/repositories/day_repository.dart';
import 'package:fajr_to_isha/data/repositories/task_repository.dart';
import 'package:fajr_to_isha/data/services/prayer_time_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DayRepository dayRepository;
  late TaskRepository taskRepository;
  late ConsistencyRepository consistencyRepository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dayRepository = DayRepository(db);
    taskRepository = TaskRepository(db);
    consistencyRepository = ConsistencyRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  DailyPrayerTimes timesFor(DateTime date) {
    return DailyPrayerTimes(
      fajr: DateTime(date.year, date.month, date.day, 5, 0),
      dhuhr: DateTime(date.year, date.month, date.day, 12, 15),
      asr: DateTime(date.year, date.month, date.day, 15, 45),
      maghrib: DateTime(date.year, date.month, date.day, 18, 20),
      isha: DateTime(date.year, date.month, date.day, 19, 45),
    );
  }

  test('aggregates real database rows into the correct consistency value',
      () async {
    final today = DateTime(2026, 9, 5);
    final weekAgo = DateTime(2026, 8, 29);

    final todayId = await dayRepository.ensureDayExists(
      date: today,
      prayerTimes: timesFor(today),
      activeTemplates: [],
    );
    final todayBlocks = await (db.select(db.prayerBlocks)
          ..where((t) => t.dayId.equals(todayId)))
        .get();
    for (final block in todayBlocks) {
      await taskRepository.setPrayerCompleted(block.id, true);
      final fixedTasks = await (db.select(db.fixedTasks)
            ..where((t) => t.prayerBlockId.equals(block.id)))
          .get();
      for (final task in fixedTasks) {
        await taskRepository.setFixedTaskCompleted(task.id, true);
      }
    }

    await dayRepository.ensureDayExists(
      date: weekAgo,
      prayerTimes: timesFor(weekAgo),
      activeTemplates: [],
    );

    final result = await consistencyRepository.calculateCurrentConsistency(
      asOf: today,
    );

    expect(result, closeTo(66.67, 0.1));
  });
}