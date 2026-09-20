import 'package:drift/native.dart';
import 'package:fajr_to_isha/data/local/database.dart';
import 'package:fajr_to_isha/data/local/tables.dart';
import 'package:fajr_to_isha/data/repositories/day_repository.dart';
import 'package:fajr_to_isha/data/repositories/task_repository.dart';
import 'package:fajr_to_isha/data/services/prayer_time_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late TaskRepository taskRepository;
  late DayRepository dayRepository;

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
    taskRepository = TaskRepository(db);
    dayRepository = DayRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('setPrayerCompleted marks completed and stamps completedAt',
      () async {
    final dayId = await dayRepository.ensureDayExists(
      date: testDate,
      prayerTimes: prayerTimes,
      activeTemplates: [],
    );
    final fajrBlock = (await (db.select(db.prayerBlocks)
              ..where((t) => t.dayId.equals(dayId)))
            .get())
        .firstWhere((b) => b.prayerType == PrayerType.fajr);

    await taskRepository.setPrayerCompleted(fajrBlock.id, true);

    final updated = await (db.select(db.prayerBlocks)
          ..where((t) => t.id.equals(fajrBlock.id)))
        .getSingle();
    expect(updated.prayerCompleted, true);
    expect(updated.completedAt, isNotNull);
  });

  test('setPrayerCompleted(false) clears completedAt', () async {
    final dayId = await dayRepository.ensureDayExists(
      date: testDate,
      prayerTimes: prayerTimes,
      activeTemplates: [],
    );
    final fajrBlock = (await (db.select(db.prayerBlocks)
              ..where((t) => t.dayId.equals(dayId)))
            .get())
        .firstWhere((b) => b.prayerType == PrayerType.fajr);

    await taskRepository.setPrayerCompleted(fajrBlock.id, true);
    await taskRepository.setPrayerCompleted(fajrBlock.id, false);

    final updated = await (db.select(db.prayerBlocks)
          ..where((t) => t.id.equals(fajrBlock.id)))
        .getSingle();
    expect(updated.prayerCompleted, false);
    expect(updated.completedAt, isNull);
  });

  test('addUserTask with recurrenceType.daily creates an instance for today',
      () async {
    final dayId = await dayRepository.ensureDayExists(
      date: testDate,
      prayerTimes: prayerTimes,
      activeTemplates: [],
    );
    final fajrBlock = (await (db.select(db.prayerBlocks)
              ..where((t) => t.dayId.equals(dayId)))
            .get())
        .firstWhere((b) => b.prayerType == PrayerType.fajr);

    await taskRepository.addUserTask(
      title: 'DSA practice',
      prayerBlockType: PrayerType.fajr,
      recurrenceType: RecurrenceType.daily,
      forDate: testDate,
      dayId: dayId,
      prayerBlockId: fajrBlock.id,
    );

    final templates = await taskRepository.getActiveTemplates();
    expect(templates.length, 1);

    final instances = await (db.select(db.userTaskInstances)
          ..where((t) => t.dayId.equals(dayId)))
        .get();
    expect(instances.length, 1);
    expect(instances.first.title, 'DSA practice');
  });

  test(
      'addUserTask with a "once" date in the future creates the template '
      'but no instance for today', () async {
    final dayId = await dayRepository.ensureDayExists(
      date: testDate,
      prayerTimes: prayerTimes,
      activeTemplates: [],
    );
    final dhuhrBlock = (await (db.select(db.prayerBlocks)
              ..where((t) => t.dayId.equals(dayId)))
            .get())
        .firstWhere((b) => b.prayerType == PrayerType.dhuhr);

    await taskRepository.addUserTask(
      title: 'Future one-off task',
      prayerBlockType: PrayerType.dhuhr,
      recurrenceType: RecurrenceType.once,
      forDate: testDate,
      dayId: dayId,
      prayerBlockId: dhuhrBlock.id,
      specificDate: DateTime(2026, 9, 10), 
    );

    final templates = await taskRepository.getActiveTemplates();
    expect(templates.length, 1); // template still created

    final instances = await (db.select(db.userTaskInstances)
          ..where((t) => t.dayId.equals(dayId)))
        .get();
    expect(instances, isEmpty);
  });
}