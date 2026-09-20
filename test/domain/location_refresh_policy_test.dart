import 'package:fajr_to_isha/domain/location_refresh_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns true when never checked before', () {
    final result = shouldAutoRefreshLocation(
      lastCheckedAt: null,
      now: DateTime(2026, 9, 5),
    );
    expect(result, true);
  });

  test('returns false when checked recently', () {
    final result = shouldAutoRefreshLocation(
      lastCheckedAt: DateTime(2026, 9, 1),
      now: DateTime(2026, 9, 5), 
    );
    expect(result, false);
  });

  test('returns true once 30 days have passed', () {
    final result = shouldAutoRefreshLocation(
      lastCheckedAt: DateTime(2026, 8, 1),
      now: DateTime(2026, 8, 31), 
    );
    expect(result, true);
  });

  test('returns false one day before the 30-day mark', () {
    final result = shouldAutoRefreshLocation(
      lastCheckedAt: DateTime(2026, 8, 1),
      now: DateTime(2026, 8, 30), 
    );
    expect(result, false);
  });
}