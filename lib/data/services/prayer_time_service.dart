import 'package:adhan/adhan.dart';

class DailyPrayerTimes {
  final DateTime fajr;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;

  const DailyPrayerTimes({
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });
}

class PrayerTimeService {
  DailyPrayerTimes calculateFor({
    required double latitude,
    required double longitude,
    required DateTime date,
    required CalculationMethod calculationMethod,
    required Madhab madhab,
  }) {
    final coordinates = Coordinates(latitude, longitude);

    final params = calculationMethod.getParameters();
    params.madhab = madhab;

    final dateComponents = DateComponents(date.year, date.month, date.day);
    final prayerTimes = PrayerTimes(coordinates, dateComponents, params);

    return DailyPrayerTimes(
      fajr: prayerTimes.fajr.toLocal(),
      dhuhr: prayerTimes.dhuhr.toLocal(),
      asr: prayerTimes.asr.toLocal(),
      maghrib: prayerTimes.maghrib.toLocal(),
      isha: prayerTimes.isha.toLocal(),
    );
  }
}

CalculationMethod calculationMethodFromName(String name) {
  switch (name) {
    case 'muslimWorldLeague':
      return CalculationMethod.muslim_world_league;
    default:
      return CalculationMethod.muslim_world_league;
  }
}

Madhab madhabFromName(String name) {
  switch (name) {
    case 'hanafi':
      return Madhab.hanafi;
    case 'shafi':
    default:
      return Madhab.shafi;
  }
}