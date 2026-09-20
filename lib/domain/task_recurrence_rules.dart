import '../data/local/tables.dart';

bool templateAppliesToDate({
  required RecurrenceType recurrenceType,
  required DateTime date,
  DateTime? specificDate,
  DateTime? startDate,
  DateTime? endDate,
  String? weekdays,
}) {
  final d = _dateOnly(date);

  switch (recurrenceType) {
    case RecurrenceType.daily:
      return true;

    case RecurrenceType.once:
      if (specificDate == null) return false;
      return d == _dateOnly(specificDate);

    case RecurrenceType.dateRange:
      if (startDate == null || endDate == null) return false;
      final start = _dateOnly(startDate);
      final end = _dateOnly(endDate);
      return !d.isBefore(start) && !d.isAfter(end);

    case RecurrenceType.customWeekdays:
      if (weekdays == null || weekdays.trim().isEmpty) return false;
      final allowed = weekdays
          .split(',')
          .map((s) => int.parse(s.trim()))
          .toSet();
      return allowed.contains(d.weekday);
  }
}

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);