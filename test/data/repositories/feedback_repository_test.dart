import 'package:drift/native.dart';
import 'package:fajr_to_isha/data/local/database.dart';
import 'package:fajr_to_isha/data/local/tables.dart';
import 'package:fajr_to_isha/data/repositories/day_repository.dart';
import 'package:fajr_to_isha/data/repositories/feedback_repository.dart';
import 'package:fajr_to_isha/data/repositories/task_repository.dart';
import 'package:fajr_to_isha/data/services/prayer_time_service.dart';
import 'package:fajr_to_isha/domain/feedback_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DayRepository dayRepository;
  late TaskRepository taskRepository;
  late FeedbackRepository feedbackRepository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dayRepository = DayRepository(db);
    taskRepository = TaskRepository(db);
    feedbackRepository = FeedbackRepository(db);
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

  Future<void> completeEverything(int dayId) async {
    final blocks = await (db.select(db.prayerBlocks)
          ..where((t) => t.dayId.equals(dayId)))
        .get();
    for (final block in blocks) {
      await taskRepository.setPrayerCompleted(block.id, true);
      final fixedTasks = await (db.select(db.fixedTasks)
            ..where((t) => t.prayerBlockId.equals(block.id)))
          .get();
      for (final task in fixedTasks) {
        await taskRepository.setFixedTaskCompleted(task.id, true);
      }
    }
  }

  Future<void> completeEverythingExceptFajr(int dayId) async {
    final blocks = await (db.select(db.prayerBlocks)
          ..where((t) => t.dayId.equals(dayId)))
        .get();
    for (final block in blocks) {
      final isFajr = block.prayerType == PrayerType.fajr;
      await taskRepository.setPrayerCompleted(block.id, !isFajr);
      final fixedTasks = await (db.select(db.fixedTasks)
            ..where((t) => t.prayerBlockId.equals(block.id)))
          .get();
      for (final task in fixedTasks) {
        await taskRepository.setFixedTaskCompleted(task.id, !isFajr);
      }
    }
  }

  test('wires real database rows into a decline result naming Fajr',
      () async {
    final today = DateTime(2026, 9, 5);

    for (var i = 6; i >= 4; i--) {
      final date = today.subtract(Duration(days: i));
      final dayId = await dayRepository.ensureDayExists(
        date: date,
        prayerTimes: timesFor(date),
        activeTemplates: [],
      );
      await completeEverything(dayId);
    }

    for (var i = 2; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dayId = await dayRepository.ensureDayExists(
        date: date,
        prayerTimes: timesFor(date),
        activeTemplates: [],
      );
      await completeEverythingExceptFajr(dayId);
    }

    final result = await feedbackRepository.generateCurrentFeedback(
      asOf: today,
    );

    expect(result.ruleType, FeedbackRuleType.decline);
    expect(result.mainMessage, contains('Fajr'));
  });
}