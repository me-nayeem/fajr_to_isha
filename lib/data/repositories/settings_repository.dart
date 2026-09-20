import 'package:drift/drift.dart';

import '../local/database.dart';
import '../local/tables.dart';

class SettingsRepository {
  final AppDatabase db;

  SettingsRepository(this.db);

  Future<AppSettings> getSettings() async {
    await db.into(db.appSettingsTable).insert(
          const AppSettingsTableCompanion(id: Value(1)),
          mode: InsertMode.insertOrIgnore,
        );

    return (db.select(db.appSettingsTable)..where((t) => t.id.equals(1)))
        .getSingle();
  }

  Future<void> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    final settings = await getSettings();
    await (db.update(db.appSettingsTable)
          ..where((t) => t.id.equals(settings.id)))
        .write(
      AppSettingsTableCompanion(
        locationLat: Value(latitude),
        locationLng: Value(longitude),
        lastLocationCheckAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markLocationCheckAttempted() async {
    final settings = await getSettings();
    await (db.update(db.appSettingsTable)
          ..where((t) => t.id.equals(settings.id)))
        .write(
      AppSettingsTableCompanion(lastLocationCheckAt: Value(DateTime.now())),
    );
  }

  Future<void> updateCalculationMethod(String methodName) async {
    final settings = await getSettings();
    await (db.update(db.appSettingsTable)
          ..where((t) => t.id.equals(settings.id)))
        .write(AppSettingsTableCompanion(
      calculationMethod: Value(methodName),
    ));
  }

  Future<void> updateMadhab(String madhabName) async {
    final settings = await getSettings();
    await (db.update(db.appSettingsTable)
          ..where((t) => t.id.equals(settings.id)))
        .write(AppSettingsTableCompanion(madhab: Value(madhabName)));
  }

  Future<void> updateNotificationTime(String hhmm) async {
    final settings = await getSettings();
    await (db.update(db.appSettingsTable)
          ..where((t) => t.id.equals(settings.id)))
        .write(AppSettingsTableCompanion(notificationTime: Value(hhmm)));
  }

  Future<void> updateManualPrayerTimes(String json) async {
    final settings = await getSettings();
    await (db.update(db.appSettingsTable)
          ..where((t) => t.id.equals(settings.id)))
        .write(AppSettingsTableCompanion(manualPrayerTimes: Value(json)));
  }
}