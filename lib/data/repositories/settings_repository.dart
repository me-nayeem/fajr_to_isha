import 'dart:convert';

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

  Future<Map<PrayerType, List<String>>> getTaskOrderPreferences() async {
    final settings = await getSettings();
    final raw = settings.taskOrderPreferences;
    if (raw == null) return {};

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final result = <PrayerType, List<String>>{};
    for (final entry in decoded.entries) {
      final prayerType = PrayerType.values.firstWhere(
        (t) => t.name == entry.key,
        orElse: () => PrayerType.fajr,
      );
      result[prayerType] = (entry.value as List).cast<String>();
    }
    return result;
  }

  Future<void> updateTaskOrderPreference(
    PrayerType prayerType,
    List<String> orderedKeys,
  ) async {
    final current = await getTaskOrderPreferences();
    current[prayerType] = orderedKeys;

    final encoded = jsonEncode(
      current.map((key, value) => MapEntry(key.name, value)),
    );

    final settings = await getSettings();
    await (db.update(db.appSettingsTable)
          ..where((t) => t.id.equals(settings.id)))
        .write(AppSettingsTableCompanion(taskOrderPreferences: Value(encoded)));
  }
}