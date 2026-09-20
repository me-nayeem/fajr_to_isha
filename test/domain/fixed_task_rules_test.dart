import 'package:fajr_to_isha/data/local/tables.dart';
import 'package:fajr_to_isha/domain/fixed_task_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Fajr has the Quran fixed task', () {
    expect(
      fixedTasksForPrayer(PrayerType.fajr),
      [FixedTaskType.quranAfterFajr],
    );
  });

  test('Asr has the personal time fixed task', () {
    expect(
      fixedTasksForPrayer(PrayerType.asr),
      [FixedTaskType.personalTimeAfterAsr],
    );
  });

  test('Isha has both the Quran and sleep fixed tasks, in order', () {
    expect(
      fixedTasksForPrayer(PrayerType.isha),
      [FixedTaskType.quranAfterIsha, FixedTaskType.sleepAfterIsha],
    );
  });

  test('Dhuhr and Maghrib have no fixed tasks', () {
    expect(fixedTasksForPrayer(PrayerType.dhuhr), isEmpty);
    expect(fixedTasksForPrayer(PrayerType.maghrib), isEmpty);
  });
}