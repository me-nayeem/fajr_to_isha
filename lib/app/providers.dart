import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/database.dart';
import '../data/repositories/consistency_repository.dart';
import '../data/repositories/day_repository.dart';
import '../data/repositories/feedback_repository.dart';
import '../data/repositories/prayer_schedule_resolver.dart';
import '../data/repositories/report_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/task_repository.dart';
import '../data/services/location_service.dart';
import '../data/services/notification_service.dart';
import '../data/services/prayer_time_service.dart';

// One AppDatabase instance for the whole app's lifetime. Closed
// automatically when the provider is disposed (effectively never, for a
// top-level provider like this, except in tests).
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final prayerTimeServiceProvider = Provider<PrayerTimeService>((ref) {
  return PrayerTimeService();
});

final prayerScheduleResolverProvider = Provider<PrayerScheduleResolver>((ref) {
  return PrayerScheduleResolver(ref.watch(prayerTimeServiceProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(appDatabaseProvider));
});

final dayRepositoryProvider = Provider<DayRepository>((ref) {
  return DayRepository(ref.watch(appDatabaseProvider));
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.watch(appDatabaseProvider));
});

final consistencyRepositoryProvider = Provider<ConsistencyRepository>((ref) {
  return ConsistencyRepository(ref.watch(appDatabaseProvider));
});

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  return FeedbackRepository(ref.watch(appDatabaseProvider));
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(ref.watch(appDatabaseProvider));
});