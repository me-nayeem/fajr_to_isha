import '../data/local/tables.dart';

class PrayerTimeEntry {
  final PrayerType type;
  final DateTime time;

  const PrayerTimeEntry({required this.type, required this.time});
}

class NextPrayerInfo {
  final PrayerType current;
  final PrayerType? next;
  final DateTime? nextTime;

  const NextPrayerInfo({required this.current, this.next, this.nextTime});
}

NextPrayerInfo determineNextPrayer(
  List<PrayerTimeEntry> entries,
  DateTime now,
) {
  final sorted = [...entries]..sort((a, b) => a.time.compareTo(b.time));

  var current = sorted.first;
  for (final entry in sorted) {
    if (!entry.time.isAfter(now)) {
      current = entry;
    }
  }

  final currentIndex = sorted.indexOf(current);
  final hasNext = currentIndex < sorted.length - 1;

  return NextPrayerInfo(
    current: current.type,
    next: hasNext ? sorted[currentIndex + 1].type : null,
    nextTime: hasNext ? sorted[currentIndex + 1].time : null,
  );
}