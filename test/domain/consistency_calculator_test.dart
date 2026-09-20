import 'package:fajr_to_isha/domain/consistency_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 9, 5);

  test('a single perfect day scores exactly 100', () {
    final result = calculateConsistencyValue(
      asOf: today,
      days: [
        DailyConsistencyInput(
          date: today,
          prayersCompleted: 5,
          fixedTasksCompleted: 4,
          fixedTasksScheduled: 4,
          userTasksCompleted: 2,
          userTasksScheduled: 2,
        ),
      ],
    );

    expect(result, 100.0);
  });

  test('a single day with everything missed scores exactly 0', () {
    final result = calculateConsistencyValue(
      asOf: today,
      days: [
        DailyConsistencyInput(
          date: today,
          prayersCompleted: 0,
          fixedTasksCompleted: 0,
          fixedTasksScheduled: 4,
          userTasksCompleted: 0,
          userTasksScheduled: 2,
        ),
      ],
    );

    expect(result, 0.0);
  });

  test(
      'a day with zero user tasks scheduled is neither penalized nor '
      'inflated by the missing component', () {
    final result = calculateConsistencyValue(
      asOf: today,
      days: [
        DailyConsistencyInput(
          date: today,
          prayersCompleted: 5,
          fixedTasksCompleted: 4,
          fixedTasksScheduled: 4,
          userTasksCompleted: 0,
          userTasksScheduled: 0, 
        ),
      ],
    );

    expect(result, 100.0);
  });

  test('recent days count more than older ones (recency decay)', () {
    final result = calculateConsistencyValue(
      asOf: today,
      halfLifeDays: 7,
      days: [
        DailyConsistencyInput(
          date: today,
          prayersCompleted: 5,
          fixedTasksCompleted: 4,
          fixedTasksScheduled: 4,
          userTasksCompleted: 2,
          userTasksScheduled: 2,
        ),
        DailyConsistencyInput(
          date: today.subtract(const Duration(days: 7)), // half weight
          prayersCompleted: 0,
          fixedTasksCompleted: 0,
          fixedTasksScheduled: 4,
          userTasksCompleted: 0,
          userTasksScheduled: 2,
        ),
      ],
    );

    expect(result, closeTo(66.67, 0.1));
  });

  test('days outside the rolling window are excluded entirely', () {
    final resultWithOldDay = calculateConsistencyValue(
      asOf: today,
      windowDays: 30,
      days: [
        DailyConsistencyInput(
          date: today,
          prayersCompleted: 5,
          fixedTasksCompleted: 4,
          fixedTasksScheduled: 4,
          userTasksCompleted: 2,
          userTasksScheduled: 2,
        ),
        DailyConsistencyInput(
          date: today.subtract(const Duration(days: 31)), // outside window
          prayersCompleted: 0,
          fixedTasksCompleted: 0,
          fixedTasksScheduled: 4,
          userTasksCompleted: 0,
          userTasksScheduled: 2,
        ),
      ],
    );

    final resultWithoutOldDay = calculateConsistencyValue(
      asOf: today,
      windowDays: 30,
      days: [
        DailyConsistencyInput(
          date: today,
          prayersCompleted: 5,
          fixedTasksCompleted: 4,
          fixedTasksScheduled: 4,
          userTasksCompleted: 2,
          userTasksScheduled: 2,
        ),
      ],
    );

    expect(resultWithOldDay, resultWithoutOldDay);
  });

  test('an empty history returns 0 rather than throwing', () {
    final result = calculateConsistencyValue(asOf: today, days: []);
    expect(result, 0.0);
  });
}