import 'dart:convert';

import 'package:drift/native.dart';
import 'package:fajr_to_isha/data/local/database.dart';
import 'package:fajr_to_isha/data/local/tables.dart';
import 'package:fajr_to_isha/data/repositories/day_repository.dart';
import 'package:fajr_to_isha/data/repositories/report_repository.dart';
import 'package:fajr_to_isha/data/repositories/task_repository.dart';
import 'package:fajr_to_isha/data/services/prayer_time_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DayRepository dayRepository;
  late TaskRepository taskRepository;
  late ReportRepository reportRepository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dayRepository = DayRepository(db);
    taskRepository = TaskRepository(db);
    reportRepository = ReportRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  DailyPrayerTimes timesFor(DateTime date) {
    return DailyPrayerTimes(
      fajr: DateTime(date.year, date.month, date.day, 5, 0),
      dhuhr: DateTime(date.year, date.month, date.day, 12, 15),
      asr: DateTime(date.year, date.month, date.day, 15, 45),
      maghrib: DateTime(date.year, date.month, date.day, 18, 20),
      isha: DateTime(date.year, date.month, date.day, 19, 45),
    );
  }

  test('generateAndSaveReport records missed prayers and is idempotent',
      () async {
    final date = DateTime(2026, 9, 1);
    final dayId = await dayRepository.ensureDayExists(
      date: date,
      prayerTimes: timesFor(date),
      activeTemplates: [],
    );

    final blocks = await (db.select(db.prayerBlocks)
          ..where((t) => t.dayId.equals(dayId)))
        .get();
    final fajrBlock =
        blocks.firstWhere((b) => b.prayerType == PrayerType.fajr);
    await taskRepository.setPrayerCompleted(fajrBlock.id, true);

    await reportRepository.generateAndSaveReport(dayId, date);
    await reportRepository.generateAndSaveReport(dayId, date);

    final reports = await db.select(db.dailyReports).get();
    expect(reports.length, 1);

    final missedPrayers = jsonDecode(reports.first.missedPrayers) as List;
    expect(missedPrayers, isNot(contains('fajr')));
    expect(missedPrayers, contains('dhuhr'));
  });

  test('finalizePastDays only finalizes days strictly before today',
      () async {
    final today = DateTime(2026, 9, 5);
    final yesterday = DateTime(2026, 9, 4);

    await dayRepository.ensureDayExists(
      date: yesterday,
      prayerTimes: timesFor(yesterday),
      activeTemplates: [],
    );
    await dayRepository.ensureDayExists(
      date: today,
      prayerTimes: timesFor(today),
      activeTemplates: [],
    );

    await reportRepository.finalizePastDays(today);

    final reports = await reportRepository.getAllReports();
    expect(reports.length, 1);
    expect(reports.first.date, yesterday);
  });

  test('getAllReports returns reports sorted most recent first', () async {
    final day1 = DateTime(2026, 9, 1);
    final day2 = DateTime(2026, 9, 2);

    final id1 = await dayRepository.ensureDayExists(
      date: day1,
      prayerTimes: timesFor(day1),
      activeTemplates: [],
    );
    final id2 = await dayRepository.ensureDayExists(
      date: day2,
      prayerTimes: timesFor(day2),
      activeTemplates: [],
    );

    await reportRepository.generateAndSaveReport(id1, day1);
    await reportRepository.generateAndSaveReport(id2, day2);

    final reports = await reportRepository.getAllReports();
    expect(reports.length, 2);
    expect(reports.first.date, day2);
    expect(reports.last.date, day1);
  });
}