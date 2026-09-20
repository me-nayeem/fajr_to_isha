import 'package:drift/native.dart';
import 'package:fajr_to_isha/data/local/database.dart';
import 'package:fajr_to_isha/data/local/tables.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('can insert and read back a Day', () async {
    final today = DateTime(2026, 9, 4);

    final id = await db.into(db.days).insert(
          DaysCompanion.insert(date: today),
        );

    final day = await (db.select(db.days)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingle();

    expect(day.date, today);
    expect(day.consistencyValue, 0);
  });

  test('can insert a PrayerBlock linked to a Day', () async {
    final dayId = await db.into(db.days).insert(
          DaysCompanion.insert(date: DateTime(2026, 9, 4)),
        );

    final blockId = await db.into(db.prayerBlocks).insert(
          PrayerBlocksCompanion.insert(
            dayId: dayId,
            prayerType: PrayerType.fajr,
            scheduledTime: DateTime(2026, 9, 4, 5, 12),
          ),
        );

    final block = await (db.select(db.prayerBlocks)
          ..where((tbl) => tbl.id.equals(blockId)))
        .getSingle();

    expect(block.dayId, dayId);
    expect(block.prayerType, PrayerType.fajr);
    expect(block.prayerCompleted, false); 
  });

  test('foreign key is enforced: cannot insert a PrayerBlock with a bad dayId',
      () async {
    expect(
      () => db.into(db.prayerBlocks).insert(
            PrayerBlocksCompanion.insert(
              dayId: 9999,
              prayerType: PrayerType.dhuhr,
              scheduledTime: DateTime(2026, 9, 4, 12, 30),
            ),
          ),
      throwsA(anything),
    );
  });
}