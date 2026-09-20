import 'package:drift/drift.dart';
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

  test('creates a Day with exactly 5 prayer blocks and correct fixed tasks',
      () async {
    final dayId = await repository.ensureDayExists(
      date: testDate,
      prayerTimes: prayerTimes,
      activeTemplates: [],
    );

    final blocks = await (db.select(db.prayerBlocks)
          ..where((t) => t.dayId.equals(dayId)))
        .get();
    expect(blocks.length, 5);

    final fajrBlock = blocks.firstWhere((b) => b.prayerType == PrayerType.fajr);
    final fajrFixedTasks = await (db.select(db.fixedTasks)
          ..where((t) => t.prayerBlockId.equals(fajrBlock.id)))
        .get();
    expect(fajrFixedTasks.map((t) => t.taskType), [FixedTaskType.quranAfterFajr]);

    final dhuhrBlock =
        blocks.firstWhere((b) => b.prayerType == PrayerType.dhuhr);
    final dhuhrFixedTasks = await (db.select(db.fixedTasks)
          ..where((t) => t.prayerBlockId.equals(dhuhrBlock.id)))
        .get();
    expect(dhuhrFixedTasks, isEmpty);
  });

  test('calling ensureDayExists twice does not duplicate any data',
      () async {
    final firstId = await repository.ensureDayExists(
      date: testDate,
      prayerTimes: prayerTimes,
      activeTemplates: [],
    );
    final secondId = await repository.ensureDayExists(
      date: testDate,
      prayerTimes: prayerTimes,
      activeTemplates: [],
    );

    expect(secondId, firstId);

    final allDays = await db.select(db.days).get();
    expect(allDays.length, 1);

    final allBlocks = await db.select(db.prayerBlocks).get();
    expect(allBlocks.length, 5); 
  });

  test('a daily template generates a UserTaskInstance in its own block',
      () async {
    final templateId = await db.into(db.taskTemplates).insert(
          TaskTemplatesCompanion.insert(
            title: 'DSA practice',
            prayerBlockType: PrayerType.fajr,
            recurrenceType: RecurrenceType.daily,
          ),
        );
    final template = await (db.select(db.taskTemplates)
          ..where((t) => t.id.equals(templateId)))
        .getSingle();

    final dayId = await repository.ensureDayExists(
      date: testDate,
      prayerTimes: prayerTimes,
      activeTemplates: [template],
    );

    final instances = await (db.select(db.userTaskInstances)
          ..where((t) => t.dayId.equals(dayId)))
        .get();
    expect(instances.length, 1);
    expect(instances.first.title, 'DSA practice');

    final fajrBlock = (await (db.select(db.prayerBlocks)
              ..where((t) => t.dayId.equals(dayId)))
            .get())
        .firstWhere((b) => b.prayerType == PrayerType.fajr);
    expect(instances.first.prayerBlockId, fajrBlock.id);
  });

  test('a "once" template for a different date is not included', () async {
    final templateId = await db.into(db.taskTemplates).insert(
          TaskTemplatesCompanion.insert(
            title: 'One-time task',
            prayerBlockType: PrayerType.dhuhr,
            recurrenceType: RecurrenceType.once,
            specificDate: Value(DateTime(2026, 9, 10)), 
          ),
        );
    final template = await (db.select(db.taskTemplates)
          ..where((t) => t.id.equals(templateId)))
        .getSingle();

    final dayId = await repository.ensureDayExists(
      date: testDate,
      prayerTimes: prayerTimes,
      activeTemplates: [template],
    );

    final instances = await (db.select(db.userTaskInstances)
          ..where((t) => t.dayId.equals(dayId)))
        .get();
    expect(instances, isEmpty);
  });
}