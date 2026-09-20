import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/local/tables.dart';
import '../../../domain/daily_view_data.dart';

sealed class TodayState {}

class TodayNeedsSetup extends TodayState {}

class TodayReady extends TodayState {
  final DailyViewData data;
  TodayReady(this.data);
}

class TodayNotifier extends AsyncNotifier<TodayState> {
  @override
  Future<TodayState> build() async {
    await ref.read(reportRepositoryProvider).finalizePastDays(DateTime.now());
    return _loadToday();
  }

  Future<void> _setupNotifications() async {
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.initialize();
    await notificationService.requestPermission();

    final settings = await ref.read(settingsRepositoryProvider).getSettings();
    final parts = settings.notificationTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    await notificationService.scheduleDailyReminder(hour, minute);
  }

  Future<TodayState> _loadToday() async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final scheduleResolver = ref.read(prayerScheduleResolverProvider);
    final dayRepo = ref.read(dayRepositoryProvider);
    final taskRepo = ref.read(taskRepositoryProvider);

    final settings = await settingsRepo.getSettings();
    final today = DateTime.now();

    final prayerTimes = scheduleResolver.resolve(
      settings: settings,
      date: today,
    );
    if (prayerTimes == null) {
      return TodayNeedsSetup();
    }

    await _setupNotifications();

    final activeTemplates = await taskRepo.getActiveTemplates();
    final orderPreferences = await settingsRepo.getTaskOrderPreferences();
    final dayId = await dayRepo.ensureDayExists(
      date: today,
      prayerTimes: prayerTimes,
      activeTemplates: activeTemplates,
      orderPreferences: orderPreferences,
    );

    final view = await dayRepo.loadDayView(dayId);
    return TodayReady(view);
  }

  Future<void> refresh() async {
    final result = await AsyncValue.guard(_loadToday);
    state = result;
  }

  Future<void> togglePrayer(int prayerBlockId, bool completed) async {
    await ref
        .read(taskRepositoryProvider)
        .setPrayerCompleted(prayerBlockId, completed);
    await refresh();
  }

  Future<void> toggleFixedTask(int fixedTaskId, bool completed) async {
    await ref
        .read(taskRepositoryProvider)
        .setFixedTaskCompleted(fixedTaskId, completed);
    await refresh();
  }

  Future<void> toggleUserTask(int instanceId, bool completed) async {
    await ref
        .read(taskRepositoryProvider)
        .setUserTaskCompleted(instanceId, completed);
    await refresh();
  }

  Future<void> addTask({
    required String title,
    required PrayerType prayerBlockType,
    required RecurrenceType recurrenceType,
    DateTime? specificDate,
    DateTime? startDate,
    DateTime? endDate,
    String? weekdays,
  }) async {
    final current = state.value;
    if (current is! TodayReady) return;

    final block = current.data.blocksByType[prayerBlockType]!.block;

    await ref.read(taskRepositoryProvider).addUserTask(
          title: title,
          prayerBlockType: prayerBlockType,
          recurrenceType: recurrenceType,
          forDate: DateTime.now(),
          dayId: current.data.day.id,
          prayerBlockId: block.id,
          specificDate: specificDate,
          startDate: startDate,
          endDate: endDate,
          weekdays: weekdays,
        );
    await refresh();
  }

  Future<void> reorderBlockTasks(
    PrayerType prayerBlockType,
    List<TaskItem> newOrder,
  ) async {
    await ref.read(taskRepositoryProvider).reorderBlockItems(newOrder);

    final orderedKeys = [
      for (final item in newOrder)
        if (item.kind != TaskItemKind.user) item.orderKey,
    ];
    await ref
        .read(settingsRepositoryProvider)
        .updateTaskOrderPreference(prayerBlockType, orderedKeys);

    await refresh();
  }
}

final todayNotifierProvider =
    AsyncNotifierProvider<TodayNotifier, TodayState>(TodayNotifier.new);