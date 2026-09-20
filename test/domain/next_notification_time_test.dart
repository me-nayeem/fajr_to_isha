import 'package:fajr_to_isha/domain/next_notification_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns today when the target time has not passed yet', () {
    final now = DateTime(2026, 9, 5, 10, 0);
    final result = nextInstanceOfTime(now: now, hour: 23, minute: 0);

    expect(result, DateTime(2026, 9, 5, 23, 0));
  });

  test('returns tomorrow when the target time has already passed today',
      () {
    final now = DateTime(2026, 9, 5, 23, 30);
    final result = nextInstanceOfTime(now: now, hour: 23, minute: 0);

    expect(result, DateTime(2026, 9, 6, 23, 0));
  });

  test('returns today when exactly at the target time', () {
    final now = DateTime(2026, 9, 5, 23, 0);
    final result = nextInstanceOfTime(now: now, hour: 23, minute: 0);

    expect(result, DateTime(2026, 9, 5, 23, 0));
  });
}