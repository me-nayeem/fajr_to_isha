import '../data/local/tables.dart';

List<FixedTaskType> fixedTasksForPrayer(PrayerType prayerType) {
  switch (prayerType) {
    case PrayerType.fajr:
      return [FixedTaskType.quranAfterFajr];
    case PrayerType.asr:
      return [FixedTaskType.personalTimeAfterAsr];
    case PrayerType.isha:
      return [FixedTaskType.quranAfterIsha, FixedTaskType.sleepAfterIsha];
    case PrayerType.dhuhr:
    case PrayerType.maghrib:
      return [];
  }
}