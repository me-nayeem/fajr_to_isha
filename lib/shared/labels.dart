import '../data/local/tables.dart';

String prayerTypeLabel(PrayerType type) {
  switch (type) {
    case PrayerType.fajr:
      return 'Fajr';
    case PrayerType.dhuhr:
      return 'Dhuhr';
    case PrayerType.asr:
      return 'Asr';
    case PrayerType.maghrib:
      return 'Maghrib';
    case PrayerType.isha:
      return 'Isha';
  }
}

String fixedTaskLabel(FixedTaskType type) {
  switch (type) {
    case FixedTaskType.quranAfterFajr:
      return 'Read Quran (10–15 min)';
    case FixedTaskType.personalTimeAfterAsr:
      return '10 minutes for yourself';
    case FixedTaskType.quranAfterIsha:
      return 'Read Quran';
    case FixedTaskType.sleepAfterIsha:
      return 'Sleep by 10–11 PM';
  }
}