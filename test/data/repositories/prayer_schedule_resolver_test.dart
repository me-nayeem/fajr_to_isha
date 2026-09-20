import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:fajr_to_isha/data/local/database.dart';
import 'package:fajr_to_isha/data/repositories/prayer_schedule_resolver.dart';
import 'package:fajr_to_isha/data/services/prayer_time_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late PrayerScheduleResolver resolver;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    resolver = PrayerScheduleResolver(PrayerTimeService());
  });

  tearDown(() async {
    await db.close();
  });

  test('uses calculated times when location is set', () async {
    final id = await db
        .into(db.appSettingsTable)
        .insert(const AppSettingsTableCompanion());
    await (db.update(db.appSettingsTable)..where((t) => t.id.equals(id)))
        .write(
      const AppSettingsTableCompanion(
        locationLat: Value(23.8103),
        locationLng: Value(90.4125),
      ),
    );
    final settings = await (db.select(db.appSettingsTable)
          ..where((t) => t.id.equals(id)))
        .getSingle();

    final result = resolver.resolve(
      settings: settings,
      date: DateTime(2026, 9, 5),
    );

    expect(result, isNotNull);
    expect(result!.fajr.isBefore(result.dhuhr), true);
  });

  test('falls back to manual times when location is not set', () async {
    final id = await db.into(db.appSettingsTable).insert(
          const AppSettingsTableCompanion(
            manualPrayerTimes: Value(
              '{"fajr":"05:12","dhuhr":"12:15","asr":"15:45","maghrib":"18:20","isha":"19:45"}',
            ),
          ),
        );
    final settings = await (db.select(db.appSettingsTable)
          ..where((t) => t.id.equals(id)))
        .getSingle();

    final result = resolver.resolve(
      settings: settings,
      date: DateTime(2026, 9, 5),
    );

    expect(result, isNotNull);
    expect(result!.fajr.hour, 5);
    expect(result.fajr.minute, 12);
    expect(result.isha.hour, 19);
    expect(result.isha.minute, 45);
  });

  test('returns null when neither location nor manual times are set',
      () async {
    final id = await db
        .into(db.appSettingsTable)
        .insert(const AppSettingsTableCompanion());
    final settings = await (db.select(db.appSettingsTable)
          ..where((t) => t.id.equals(id)))
        .getSingle();

    final result = resolver.resolve(
      settings: settings,
      date: DateTime(2026, 9, 5),
    );

    expect(result, isNull);
  });

  test('returns null (not a crash) when manual times are malformed',
      () async {
    final id = await db.into(db.appSettingsTable).insert(
          const AppSettingsTableCompanion(
            manualPrayerTimes:  Value('not valid json'),
          ),
        );
    final settings = await (db.select(db.appSettingsTable)
          ..where((t) => t.id.equals(id)))
        .getSingle();

    final result = resolver.resolve(
      settings: settings,
      date: DateTime(2026, 9, 5),
    );

    expect(result, isNull);
  });
}