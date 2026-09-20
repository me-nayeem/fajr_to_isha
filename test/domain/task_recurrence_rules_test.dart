import 'package:fajr_to_isha/data/local/tables.dart';
import 'package:fajr_to_isha/domain/task_recurrence_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('daily', () {
    test('always applies, regardless of date', () {
      expect(
        templateAppliesToDate(
          recurrenceType: RecurrenceType.daily,
          date: DateTime(2026, 1, 1),
        ),
        true,
      );
      expect(
        templateAppliesToDate(
          recurrenceType: RecurrenceType.daily,
          date: DateTime(2030, 12, 31),
        ),
        true,
      );
    });
  });

  group('once', () {
    test('applies only on the exact specific date', () {
      expect(
        templateAppliesToDate(
          recurrenceType: RecurrenceType.once,
          date: DateTime(2026, 9, 5),
          specificDate: DateTime(2026, 9, 5),
        ),
        true,
      );
    });

    test('does not apply on a different date', () {
      expect(
        templateAppliesToDate(
          recurrenceType: RecurrenceType.once,
          date: DateTime(2026, 9, 6),
          specificDate: DateTime(2026, 9, 5),
        ),
        false,
      );
    });

    test('ignores time-of-day when comparing dates', () {
      expect(
        templateAppliesToDate(
          recurrenceType: RecurrenceType.once,
          date: DateTime(2026, 9, 5, 23, 59),
          specificDate: DateTime(2026, 9, 5, 0, 1),
        ),
        true,
      );
    });

    test('false when specificDate is missing', () {
      expect(
        templateAppliesToDate(
          recurrenceType: RecurrenceType.once,
          date: DateTime(2026, 9, 5),
        ),
        false,
      );
    });
  });

  group('dateRange', () {
    final start = DateTime(2026, 9, 1);
    final end = DateTime(2026, 9, 10);

    test('applies on the start boundary (inclusive)', () {
      expect(
        templateAppliesToDate(
          recurrenceType: RecurrenceType.dateRange,
          date: start,
          startDate: start,
          endDate: end,
        ),
        true,
      );
    });

    test('applies on the end boundary (inclusive)', () {
      expect(
        templateAppliesToDate(
          recurrenceType: RecurrenceType.dateRange,
          date: end,
          startDate: start,
          endDate: end,
        ),
        true,
      );
    });

    test('applies in the middle of the range', () {
      expect(
        templateAppliesToDate(
          recurrenceType: RecurrenceType.dateRange,
          date: DateTime(2026, 9, 5),
          startDate: start,
          endDate: end,
        ),
        true,
      );
    });

    test('does not apply before the range', () {
      expect(
        templateAppliesToDate(
          recurrenceType: RecurrenceType.dateRange,
          date: DateTime(2026, 8, 31),
          startDate: start,
          endDate: end,
        ),
        false,
      );
    });

    test('does not apply after the range', () {
      expect(
        templateAppliesToDate(
          recurrenceType: RecurrenceType.dateRange,
          date: DateTime(2026, 9, 11),
          startDate: start,
          endDate: end,
        ),
        false,
      );
    });

    test('false when startDate or endDate is missing', () {
      expect(
        templateAppliesToDate(
          recurrenceType: RecurrenceType.dateRange,
          date: DateTime(2026, 9, 5),
          startDate: start,
        ),
        false,
      );
    });
  });

  group('customWeekdays', () {
    test("applies when today's weekday is in the list", () {
      expect(
        templateAppliesToDate(
          recurrenceType: RecurrenceType.customWeekdays,
          date: DateTime(2026, 9, 7),
          weekdays: '1,3,5', // Mon, Wed, Fri
        ),
        true,
      );
    });

    test("does not apply when today's weekday is not in the list", () {
      expect(
        templateAppliesToDate(
          recurrenceType: RecurrenceType.customWeekdays,
          date: DateTime(2026, 9, 8),
          weekdays: '1,3,5',
        ),
        false,
      );
    });

    test('handles extra whitespace around numbers', () {
      expect(
        templateAppliesToDate(
          recurrenceType: RecurrenceType.customWeekdays,
          date: DateTime(2026, 9, 7),
          weekdays: ' 1 , 3 , 5 ',
        ),
        true,
      );
    });

    test('false when weekdays string is null or empty', () {
      expect(
        templateAppliesToDate(
          recurrenceType: RecurrenceType.customWeekdays,
          date: DateTime(2026, 9, 7),
        ),
        false,
      );
      expect(
        templateAppliesToDate(
          recurrenceType: RecurrenceType.customWeekdays,
          date: DateTime(2026, 9, 7),
          weekdays: '',
        ),
        false,
      );
    });
  });
}