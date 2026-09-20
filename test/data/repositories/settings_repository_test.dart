import 'package:drift/native.dart';
import 'package:fajr_to_isha/data/local/database.dart';
import 'package:fajr_to_isha/data/repositories/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SettingsRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = SettingsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('creates default settings on first access', () async {
    final settings = await repository.getSettings();

    expect(settings.calculationMethod, 'muslimWorldLeague');
    expect(settings.madhab, 'shafi');
    expect(settings.locationLat, isNull);
    expect(settings.locationLng, isNull);
  });

  test('returns the same row on repeated access, not a new one each time',
      () async {
    final first = await repository.getSettings();
    final second = await repository.getSettings();

    expect(second.id, first.id);

    final allRows = await db.select(db.appSettingsTable).get();
    expect(allRows.length, 1);
  });

  test('updateLocation stores coordinates and records the check time',
      () async {
    await repository.updateLocation(latitude: 23.8103, longitude: 90.4125);

    final settings = await repository.getSettings();
    expect(settings.locationLat, 23.8103);
    expect(settings.locationLng, 90.4125);
    expect(settings.lastLocationCheckAt, isNotNull);
  });

  test('updateMadhab changes only the madhab field', () async {
    await repository.updateMadhab('hanafi');

    final settings = await repository.getSettings();
    expect(settings.madhab, 'hanafi');
    expect(settings.calculationMethod, 'muslimWorldLeague'); // unchanged
  });
}