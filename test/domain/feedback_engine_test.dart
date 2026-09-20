import 'package:fajr_to_isha/data/local/tables.dart';
import 'package:fajr_to_isha/domain/feedback_engine.dart';
import 'package:flutter_test/flutter_test.dart';

DailyPrayerRecord record({
  required DateTime date,
  required double dayScore,
  Map<PrayerType, bool>? prayerOverrides,
  Map<FixedTaskType, bool>? fixedOverrides,
}) {
  final prayers = {
    for (final type in PrayerType.values) type: true,
    ...?prayerOverrides,
  };
  final fixed = {
    for (final type in FixedTaskType.values) type: true,
    ...?fixedOverrides,
  };
  return DailyPrayerRecord(
    date: date,
    prayerCompletion: prayers,
    fixedTaskCompletion: fixed,
    dayScore: dayScore,
  );
}

void main() {
  final today = DateTime(2026, 9, 5);

  test('decline rule fires and names the weakest prayer', () {
    final history = <DailyPrayerRecord>[
      for (var i = 6; i >= 4; i--)
        record(date: today.subtract(Duration(days: i)), dayScore: 1.0),
      for (var i = 2; i >= 0; i--)
        record(
          date: today.subtract(Duration(days: i)),
          dayScore: 0.7,
          prayerOverrides: {PrayerType.fajr: false},
        ),
    ];

    final result = generateFeedback(history: history, asOf: today);

    expect(result.ruleType, FeedbackRuleType.decline);
    expect(result.mainMessage, contains('Fajr'));
  });

  test('weak point rule fires when overall score is stable', () {
    final history = <DailyPrayerRecord>[
      for (var i = 6; i >= 4; i--)
        record(date: today.subtract(Duration(days: i)), dayScore: 0.9),
      record(
        date: today.subtract(const Duration(days: 2)),
        dayScore: 0.85,
        prayerOverrides: {PrayerType.fajr: false},
      ),
      record(
        date: today.subtract(const Duration(days: 1)),
        dayScore: 0.85,
        prayerOverrides: {PrayerType.fajr: false},
      ),
      record(date: today, dayScore: 0.9),
    ];

    final result = generateFeedback(history: history, asOf: today);

    expect(result.ruleType, FeedbackRuleType.weakPoint);
    expect(result.mainMessage, contains('Fajr'));
  });

  test('improvement rule fires on a sustained upward trend', () {
    final history = <DailyPrayerRecord>[
      for (var i = 13; i >= 7; i--)
        record(date: today.subtract(Duration(days: i)), dayScore: 0.5),
      for (var i = 6; i >= 0; i--)
        record(date: today.subtract(Duration(days: i)), dayScore: 0.9),
    ];

    final result = generateFeedback(history: history, asOf: today);

    expect(result.ruleType, FeedbackRuleType.improvement);
  });

  test('perfect day rule fires when today is fully completed and no '
      'other rule applies', () {
    final history = <DailyPrayerRecord>[
      record(date: today, dayScore: 1.0),
    ];

    final result = generateFeedback(history: history, asOf: today);

    expect(result.ruleType, FeedbackRuleType.perfectDay);
  });

  test('stable rule fires when today is incomplete and history is too '
      'short for other rules', () {
    final history = <DailyPrayerRecord>[
      record(
        date: today,
        dayScore: 0.8,
        prayerOverrides: {PrayerType.asr: false},
      ),
    ];

    final result = generateFeedback(history: history, asOf: today);

    expect(result.ruleType, FeedbackRuleType.stable);
  });

  test('decline outranks perfect day when today is perfect but the '
      'trailing average still dropped', () {
    final history = <DailyPrayerRecord>[
      for (var i = 6; i >= 4; i--)
        record(date: today.subtract(Duration(days: i)), dayScore: 1.0),
      record(
        date: today.subtract(const Duration(days: 2)),
        dayScore: 0.3,
        prayerOverrides: {PrayerType.dhuhr: false},
      ),
      record(
        date: today.subtract(const Duration(days: 1)),
        dayScore: 0.3,
        prayerOverrides: {PrayerType.dhuhr: false},
      ),
      record(date: today, dayScore: 1.0),
    ];

    final result = generateFeedback(history: history, asOf: today);

    expect(result.ruleType, FeedbackRuleType.decline);
    expect(result.mainMessage, contains('Dhuhr'));
  });
}