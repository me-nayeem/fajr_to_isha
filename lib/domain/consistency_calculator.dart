import 'dart:math' as math;

class DailyConsistencyInput {
  final DateTime date;
  final int prayersCompleted;
  final int fixedTasksCompleted;
  final int fixedTasksScheduled;
  final int userTasksCompleted;
  final int userTasksScheduled;

  const DailyConsistencyInput({
    required this.date,
    required this.prayersCompleted,
    required this.fixedTasksCompleted,
    required this.fixedTasksScheduled,
    required this.userTasksCompleted,
    required this.userTasksScheduled,
  });
}

double calculateDayScore(
  DailyConsistencyInput day, {
  double prayerWeight = 0.5,
  double fixedWeight = 0.3,
  double userWeight = 0.2,
}) {
  final prayerScore = day.prayersCompleted / 5.0;

  double presentWeight = prayerWeight;
  double weightedDayScore = prayerScore * prayerWeight;

  if (day.fixedTasksScheduled > 0) {
    final fixedScore = day.fixedTasksCompleted / day.fixedTasksScheduled;
    presentWeight += fixedWeight;
    weightedDayScore += fixedScore * fixedWeight;
  }

  if (day.userTasksScheduled > 0) {
    final userScore = day.userTasksCompleted / day.userTasksScheduled;
    presentWeight += userWeight;
    weightedDayScore += userScore * userWeight;
  }

  return weightedDayScore / presentWeight;
}

double calculateConsistencyValue({
  required List<DailyConsistencyInput> days,
  required DateTime asOf,
  int windowDays = 30,
  int halfLifeDays = 7,
  double prayerWeight = 0.5,
  double fixedWeight = 0.3,
  double userWeight = 0.2,
}) {
  final cutoff = asOf.subtract(Duration(days: windowDays));

  double weightedScoreSum = 0;
  double totalDecayWeight = 0;

  for (final day in days) {
    if (day.date.isBefore(cutoff) || day.date.isAfter(asOf)) continue;

    final daysAgo = asOf.difference(day.date).inDays;
    final decay = math.pow(0.5, daysAgo / halfLifeDays).toDouble();

    final dayScore = calculateDayScore(
      day,
      prayerWeight: prayerWeight,
      fixedWeight: fixedWeight,
      userWeight: userWeight,
    );

    weightedScoreSum += dayScore * decay;
    totalDecayWeight += decay;
  }

  if (totalDecayWeight == 0) return 0.0;

  return (weightedScoreSum / totalDecayWeight) * 100;
}