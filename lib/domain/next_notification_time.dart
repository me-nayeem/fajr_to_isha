DateTime nextInstanceOfTime({
  required DateTime now,
  required int hour,
  required int minute,
}) {
  var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
  if (scheduled.isBefore(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }
  return scheduled;
}