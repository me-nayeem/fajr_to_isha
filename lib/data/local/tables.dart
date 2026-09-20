import 'package:drift/drift.dart';

enum PrayerType { fajr, dhuhr, asr, maghrib, isha }

enum FixedTaskType {
  quranAfterFajr,
  personalTimeAfterAsr,
  quranAfterIsha,
  sleepAfterIsha,
}

enum RecurrenceType { once, daily, dateRange, customWeekdays }

// Tables 

@DataClassName('Day')
class Days extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime().unique()();
  RealColumn get consistencyValue => real().withDefault(const Constant(0))();
  DateTimeColumn get calculatedAt => dateTime().nullable()();
}

@DataClassName('PrayerBlock')
class PrayerBlocks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dayId => integer().references(Days, #id)();
  TextColumn get prayerType => textEnum<PrayerType>()();
  DateTimeColumn get scheduledTime => dateTime()();
  BoolColumn get prayerCompleted =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

@DataClassName('FixedTask')
class FixedTasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get prayerBlockId => integer().references(PrayerBlocks, #id)();
  TextColumn get taskType => textEnum<FixedTaskType>()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

@DataClassName('TaskTemplate')
class TaskTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get prayerBlockType => textEnum<PrayerType>()();
  TextColumn get recurrenceType => textEnum<RecurrenceType>()();

  DateTimeColumn get specificDate => dateTime().nullable()();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get weekdays => text().nullable()();

  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('UserTaskInstance')
class UserTaskInstances extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get templateId =>
      integer().nullable().references(TaskTemplates, #id)();
  IntColumn get dayId => integer().references(Days, #id)();
  IntColumn get prayerBlockId => integer().references(PrayerBlocks, #id)();
  TextColumn get title => text()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

@DataClassName('DailyReport')
class DailyReports extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dayId => integer().references(Days, #id)();
  DateTimeColumn get generatedAt => dateTime()();
  TextColumn get missedPrayers => text()();
  TextColumn get missedFixedTasks => text()();
  TextColumn get missedUserTasks => text()();
  RealColumn get consistencyValue => real()();
  TextColumn get feedbackMessage => text()();
}

@DataClassName('AppSettings')
class AppSettingsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get calculationMethod =>
      text().withDefault(const Constant('muslimWorldLeague'))();
  TextColumn get madhab => text().withDefault(const Constant('shafi'))();
  RealColumn get locationLat => real().nullable()();
  RealColumn get locationLng => real().nullable()();
  TextColumn get manualPrayerTimes => text().nullable()(); 
  TextColumn get notificationTime =>
      text().withDefault(const Constant('23:00'))();
  DateTimeColumn get lastLocationCheckAt => dateTime().nullable()();
}
