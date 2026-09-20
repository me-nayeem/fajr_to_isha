import 'package:drift/native.dart';
import 'package:fajr_to_isha/data/local/database.dart';
import 'package:fajr_to_isha/data/local/tables.dart';
import 'package:fajr_to_isha/data/repositories/day_repository.dart';
import 'package:fajr_to_isha/data/services/prayer_time_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DayRepository repository;

  final testDate = DateTime(2026, 9, 5);
  final prayerTimes = DailyPrayerTimes(
    fajr: DateTime(2026, 9, 5, 5, 0),
    dhuhr: DateTime(2026, 9, 5, 12, 15),
    asr: DateTime(2026, 9, 5, 15, 45),
    maghrib: DateTime(2026, 9, 5, 18, 20),
    isha: DateTime(2026, 9, 5, 19, 45),
  );

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DayRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('loadDayView returns all 5 blocks in Fajr-to-Isha order', () async {
    final dayId = await repository.ensureDayExists(
      date: testDate,
      prayerTimes: prayerTimes,
      activeTemplates: [],
    );

    final view = await repository.loadDayView(dayId);

    expect(view.orderedBlocks.length, 5);
    expect(view.orderedBlocks[0].block.prayerType, PrayerType.fajr);
    expect(view.orderedBlocks[1].block.prayerType, PrayerType.dhuhr);
    expect(view.orderedBlocks[2].block.prayerType, PrayerType.asr);
    expect(view.orderedBlocks[3].block.prayerType, PrayerType.maghrib);
    expect(view.orderedBlocks[4].block.prayerType, PrayerType.isha);
  });

  test('loadDayView attaches the correct fixed tasks per block', () async {
    final dayId = await repository.ensureDayExists(
      date: testDate,
      prayerTimes: prayerTimes,
      activeTemplates: [],
    );

    final view = await repository.loadDayView(dayId);

    final fajr = view.blocksByType[PrayerType.fajr]!;
    expect(fajr.fixedTasks.map((t) => t.taskType), [FixedTaskType.quranAfterFajr]);

    final isha = view.blocksByType[PrayerType.isha]!;
    expect(
      isha.fixedTasks.map((t) => t.taskType).toSet(),
      {FixedTaskType.quranAfterIsha, FixedTaskType.sleepAfterIsha},
    );

    final dhuhr = view.blocksByType[PrayerType.dhuhr]!;
    expect(dhuhr.fixedTasks, isEmpty);
  });
}