import 'dart:convert';

import '../local/database.dart';
import '../local/tables.dart';
import 'consistency_repository.dart';
import 'feedback_repository.dart';

class DailyReportView {
  final DateTime date;
  final double consistencyValue;
  final String feedbackMessage;
  final List<PrayerType> missedPrayers;
  final List<FixedTaskType> missedFixedTasks;
  final List<String> missedUserTasks;

  const DailyReportView({
    required this.date,
    required this.consistencyValue,
    required this.feedbackMessage,
    required this.missedPrayers,
    required this.missedFixedTasks,
    required this.missedUserTasks,
  });
}

class ReportRepository {
  final AppDatabase db;
  late final ConsistencyRepository _consistencyRepository =
      ConsistencyRepository(db);
  late final FeedbackRepository _feedbackRepository = FeedbackRepository(db);

  ReportRepository(this.db);

  Future<void> generateAndSaveReport(int dayId, DateTime date) async {
    final existing = await (db.select(db.dailyReports)
          ..where((t) => t.dayId.equals(dayId)))
        .getSingleOrNull();
    if (existing != null) return;

    final blocks = await (db.select(db.prayerBlocks)
          ..where((t) => t.dayId.equals(dayId)))
        .get();

    final missedPrayers = <String>[];
    final missedFixedTasks = <String>[];
    final missedUserTasks = <String>[];

    for (final block in blocks) {
      if (!block.prayerCompleted) {
        missedPrayers.add(block.prayerType.name);
      }

      final fixedTasks = await (db.select(db.fixedTasks)
            ..where((t) => t.prayerBlockId.equals(block.id)))
          .get();
      for (final task in fixedTasks) {
        if (!task.completed) {
          missedFixedTasks.add(task.taskType.name);
        }
      }

      final userTasks = await (db.select(db.userTaskInstances)
            ..where((t) => t.prayerBlockId.equals(block.id)))
          .get();
      for (final task in userTasks) {
        if (!task.completed) {
          missedUserTasks.add(task.title);
        }
      }
    }

    final consistencyValue = await _consistencyRepository
        .calculateCurrentConsistency(asOf: date);
    final feedback =
        await _feedbackRepository.generateCurrentFeedback(asOf: date);

    await db.into(db.dailyReports).insert(
          DailyReportsCompanion.insert(
            dayId: dayId,
            generatedAt: DateTime.now(),
            missedPrayers: jsonEncode(missedPrayers),
            missedFixedTasks: jsonEncode(missedFixedTasks),
            missedUserTasks: jsonEncode(missedUserTasks),
            consistencyValue: consistencyValue,
            feedbackMessage: feedback.mainMessage,
          ),
        );
  }

  Future<void> finalizePastDays(DateTime today) async {
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    final allDays = await db.select(db.days).get();
    for (final day in allDays) {
      if (day.date.isBefore(todayDateOnly)) {
        await generateAndSaveReport(day.id, day.date);
      }
    }
  }

  Future<List<DailyReportView>> getAllReports() async {
    final reports = await db.select(db.dailyReports).get();
    final result = <DailyReportView>[];

    for (final report in reports) {
      final day = await (db.select(db.days)
            ..where((t) => t.id.equals(report.dayId)))
          .getSingle();

      final missedPrayers = (jsonDecode(report.missedPrayers) as List)
          .map((e) => PrayerType.values.byName(e as String))
          .toList();
      final missedFixedTasks = (jsonDecode(report.missedFixedTasks) as List)
          .map((e) => FixedTaskType.values.byName(e as String))
          .toList();
      final missedUserTasks =
          (jsonDecode(report.missedUserTasks) as List).cast<String>();

      result.add(DailyReportView(
        date: day.date,
        consistencyValue: report.consistencyValue,
        feedbackMessage: report.feedbackMessage,
        missedPrayers: missedPrayers,
        missedFixedTasks: missedFixedTasks,
        missedUserTasks: missedUserTasks,
      ));
    }

    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }
}