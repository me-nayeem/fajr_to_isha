import 'package:fajr_to_isha/data/local/tables.dart';
import 'package:fajr_to_isha/domain/next_prayer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final entries = [
    PrayerTimeEntry(type: PrayerType.fajr, time: DateTime(2026, 9, 11, 5, 0)),
    PrayerTimeEntry(type: PrayerType.dhuhr, time: DateTime(2026, 9, 11, 12, 15)),
    PrayerTimeEntry(type: PrayerType.asr, time: DateTime(2026, 9, 11, 15, 45)),
    PrayerTimeEntry(type: PrayerType.maghrib, time: DateTime(2026, 9, 11, 18, 20)),
    PrayerTimeEntry(type: PrayerType.isha, time: DateTime(2026, 9, 11, 19, 45)),
  ];

  test('before Fajr, current is Fajr and next is Dhuhr', () {
    final result = determineNextPrayer(entries, DateTime(2026, 9, 11, 4, 0));

    expect(result.current, PrayerType.fajr);
    expect(result.next, PrayerType.dhuhr);
  });

  test('between Dhuhr and Asr, current is Dhuhr and next is Asr', () {
    final result = determineNextPrayer(entries, DateTime(2026, 9, 11, 13, 0));

    expect(result.current, PrayerType.dhuhr);
    expect(result.next, PrayerType.asr);
    expect(result.nextTime, DateTime(2026, 9, 11, 15, 45));
  });

  test('after Isha, current is Isha and there is no next prayer', () {
    final result = determineNextPrayer(entries, DateTime(2026, 9, 11, 22, 0));

    expect(result.current, PrayerType.isha);
    expect(result.next, isNull);
    expect(result.nextTime, isNull);
  });

  test('exactly at a prayer time, that prayer becomes current', () {
    final result = determineNextPrayer(entries, DateTime(2026, 9, 11, 15, 45));

    expect(result.current, PrayerType.asr);
    expect(result.next, PrayerType.maghrib);
  });
}