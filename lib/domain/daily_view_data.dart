import '../../data/local/database.dart';
import '../../data/local/tables.dart';

class BlockView {
  final PrayerBlock block;
  final List<FixedTask> fixedTasks;
  final List<UserTaskInstance> userTasks;

  const BlockView({
    required this.block,
    required this.fixedTasks,
    required this.userTasks,
  });
}

class DailyViewData {
  final Day day;
  final Map<PrayerType, BlockView> blocksByType;

  const DailyViewData({required this.day, required this.blocksByType});

  /// Fajr through Isha, in display order.
  List<BlockView> get orderedBlocks => [
        blocksByType[PrayerType.fajr]!,
        blocksByType[PrayerType.dhuhr]!,
        blocksByType[PrayerType.asr]!,
        blocksByType[PrayerType.maghrib]!,
        blocksByType[PrayerType.isha]!,
      ];
}