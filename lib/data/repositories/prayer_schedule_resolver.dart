import 'dart:convert';

import '../local/database.dart';
import '../services/prayer_time_service.dart';

class PrayerScheduleResolver {
  final PrayerTimeService prayerTimeService;

  PrayerScheduleResolver(this.prayerTimeService);

  DailyPrayerTimes? resolve({
    required AppSettings settings,
    required DateTime date,
  }) {
    if (settings.locationLat != null && settings.locationLng != null) {
      return prayerTimeService.calculateFor(
        latitude: settings.locationLat!,
        longitude: settings.locationLng!,
        date: date,
        calculationMethod:
            calculationMethodFromName(settings.calculationMethod),
        madhab: madhabFromName(settings.madhab),
      );
    }

    if (settings.manualPrayerTimes != null) {
      return _parseManualTimes(settings.manualPrayerTimes!, date);
    }

    return null;
  }

  DailyPrayerTimes? _parseManualTimes(String json, DateTime date) {
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;

      DateTime timeFor(String key) {
        final parts = (map[key] as String).split(':');
        return DateTime(
          date.year,
          date.month,
          date.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      }

      return DailyPrayerTimes(
        fajr: timeFor('fajr'),
        dhuhr: timeFor('dhuhr'),
        asr: timeFor('asr'),
        maghrib: timeFor('maghrib'),
        isha: timeFor('isha'),
      );
    } catch (_) {
      return null;
    }
  }
}