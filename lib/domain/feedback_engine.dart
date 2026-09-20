import '../data/local/tables.dart';
import '../shared/labels.dart';

enum FeedbackRuleType { decline, weakPoint, improvement, stable, perfectDay }

class FeedbackResult {
  final FeedbackRuleType ruleType;
  final String mainMessage;
  final String? supportingStat;

  const FeedbackResult({
    required this.ruleType,
    required this.mainMessage,
    this.supportingStat,
  });
}

class DailyPrayerRecord {
  final DateTime date;
  final Map<PrayerType, bool> prayerCompletion;
  final Map<FixedTaskType, bool> fixedTaskCompletion;
  final double dayScore;

  const DailyPrayerRecord({
    required this.date,
    required this.prayerCompletion,
    required this.fixedTaskCompletion,
    required this.dayScore,
  });
}

class _WeakItem {
  final String label;
  final int missed;
  final int occurrences;

  const _WeakItem(this.label, this.missed, this.occurrences);
}

FeedbackResult generateFeedback({
  required List<DailyPrayerRecord> history,
  required DateTime asOf,
}) {
  final sorted = [...history]..sort((a, b) => a.date.compareTo(b.date));

  final last3 = _daysInRange(
    sorted,
    asOf.subtract(const Duration(days: 2)),
    asOf,
  );
  final prior3 = _daysInRange(
    sorted,
    asOf.subtract(const Duration(days: 6)),
    asOf.subtract(const Duration(days: 4)),
  );

  if (last3.length == 3 && prior3.length == 3) {
    final recentAvg = _average(last3.map((d) => d.dayScore));
    final priorAvg = _average(prior3.map((d) => d.dayScore));

    if (priorAvg - recentAvg >= 0.15) {
      final weak = _findWeakestItem(last3);
      if (weak != null && weak.missed > 0) {
        return FeedbackResult(
          ruleType: FeedbackRuleType.decline,
          mainMessage:
              'Your consistency has dropped this week. You are most inconsistent with ${weak.label}. Focus on fixing that first.',
          supportingStat:
              '${weak.label}: ${weak.occurrences - weak.missed}/${weak.occurrences} this week',
        );
      }
    }
  }

  if (last3.length == 3) {
    final weak = _findWeakestItem(last3);
    if (weak != null && weak.missed >= 2) {
      return FeedbackResult(
        ruleType: FeedbackRuleType.weakPoint,
        mainMessage:
            'Your prayers have been consistent, but you have missed ${weak.label} several times this week.',
        supportingStat:
            '${weak.label}: ${weak.occurrences - weak.missed}/${weak.occurrences} this week',
      );
    }
  }

  final last7 = _daysInRange(
    sorted,
    asOf.subtract(const Duration(days: 6)),
    asOf,
  );
  final prior7 = _daysInRange(
    sorted,
    asOf.subtract(const Duration(days: 13)),
    asOf.subtract(const Duration(days: 7)),
  );

  if (last7.length == 7 && prior7.length == 7) {
    final recentAvg = _average(last7.map((d) => d.dayScore));
    final priorAvg = _average(prior7.map((d) => d.dayScore));

    if (recentAvg - priorAvg >= 0.05) {
      return FeedbackResult(
        ruleType: FeedbackRuleType.improvement,
        mainMessage:
            'You have maintained your routine for the last 7 days. Your consistency is improving.',
        supportingStat: '7-day average: ${(recentAvg * 100).round()}%',
      );
    }
  }

  final todayRecords =
      sorted.where((d) => _isSameDate(d.date, asOf)).toList();
  if (todayRecords.isNotEmpty) {
    final today = todayRecords.first;
    final allPrayers = today.prayerCompletion.values.every((v) => v);
    final allFixed = today.fixedTaskCompletion.values.every((v) => v);
    if (allPrayers && allFixed) {
      return const FeedbackResult(
        ruleType: FeedbackRuleType.perfectDay,
        mainMessage: 'You completed everything MaSha\'Allah.',
      );
    }
  }

  return const FeedbackResult(
    ruleType: FeedbackRuleType.stable,
    mainMessage:
        'Your consistency this week is similar to last week no major changes.',
  );
}

_WeakItem? _findWeakestItem(List<DailyPrayerRecord> window) {
  final prayerMisses = <PrayerType, int>{};
  final fixedMisses = <FixedTaskType, int>{};

  for (final day in window) {
    day.prayerCompletion.forEach((type, completed) {
      if (!completed) {
        prayerMisses[type] = (prayerMisses[type] ?? 0) + 1;
      }
    });
    day.fixedTaskCompletion.forEach((type, completed) {
      if (!completed) {
        fixedMisses[type] = (fixedMisses[type] ?? 0) + 1;
      }
    });
  }

  _WeakItem? worst;

  for (final type in PrayerType.values) {
    final missed = prayerMisses[type] ?? 0;
    if (worst == null || missed > worst.missed) {
      worst = _WeakItem(prayerTypeLabel(type), missed, window.length);
    }
  }

  for (final type in FixedTaskType.values) {
    final missed = fixedMisses[type] ?? 0;
    if (worst == null || missed > worst.missed) {
      worst = _WeakItem(fixedTaskLabel(type), missed, window.length);
    }
  }

  return worst;
}

List<DailyPrayerRecord> _daysInRange(
  List<DailyPrayerRecord> sorted,
  DateTime start,
  DateTime end,
) {
  final s = _dateOnly(start);
  final e = _dateOnly(end);
  return sorted
      .where((d) => !d.date.isBefore(s) && !d.date.isAfter(e))
      .toList();
}

double _average(Iterable<double> values) {
  final list = values.toList();
  if (list.isEmpty) return 0;
  return list.reduce((a, b) => a + b) / list.length;
}

bool _isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);