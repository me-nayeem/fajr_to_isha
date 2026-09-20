import 'package:adhan/adhan.dart';
import 'package:fajr_to_isha/data/services/prayer_time_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = PrayerTimeService();

  const lat = 23.8103;
  const lng = 90.4125;

  test('prayer times fall in correct chronological order', () {
    final times = service.calculateFor(
      latitude: lat,
      longitude: lng,
      date: DateTime(2026, 6, 21),
      calculationMethod: CalculationMethod.muslim_world_league,
      madhab: Madhab.shafi,
    );

    expect(times.fajr.isBefore(times.dhuhr), true);
    expect(times.dhuhr.isBefore(times.asr), true);
    expect(times.asr.isBefore(times.maghrib), true);
    expect(times.maghrib.isBefore(times.isha), true);
  });

  test('Hanafi Asr is later than Shafi Asr on the same day', () {
    final shafi = service.calculateFor(
      latitude: lat,
      longitude: lng,
      date: DateTime(2026, 6, 21),
      calculationMethod: CalculationMethod.muslim_world_league,
      madhab: Madhab.shafi,
    );
    final hanafi = service.calculateFor(
      latitude: lat,
      longitude: lng,
      date: DateTime(2026, 6, 21),
      calculationMethod: CalculationMethod.muslim_world_league,
      madhab: Madhab.hanafi,
    );

    expect(hanafi.asr.isAfter(shafi.asr), true);
  });

  test('Fajr-to-Isha span is longer in summer than winter (seasonal effect)',
      () {
    const londonLat = 51.5074;
    const londonLng = -0.1278;

    final summer = service.calculateFor(
      latitude: londonLat,
      longitude: londonLng,
      date: DateTime(2026, 6, 21), 
      calculationMethod: CalculationMethod.muslim_world_league,
      madhab: Madhab.shafi,
    );
    final winter = service.calculateFor(
      latitude: londonLat,
      longitude: londonLng,
      date: DateTime(2026, 12, 21), 
      calculationMethod: CalculationMethod.muslim_world_league,
      madhab: Madhab.shafi,
    );

    final summerSpan = summer.isha.difference(summer.fajr);
    final winterSpan = winter.isha.difference(winter.fajr);

    expect(summerSpan.inMinutes, greaterThan(winterSpan.inMinutes));
  });

  test('calculationMethodFromName and madhabFromName round-trip correctly',
      () {
    expect(
      calculationMethodFromName('muslim_world_league'),
      CalculationMethod.muslim_world_league,
    );
    expect(madhabFromName('shafi'), Madhab.shafi);
    expect(madhabFromName('hanafi'), Madhab.hanafi);
  });
}