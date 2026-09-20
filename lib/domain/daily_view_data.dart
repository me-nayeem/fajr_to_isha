import '../../data/local/database.dart';
import '../../data/local/tables.dart';

enum TaskItemKind { prayer, fixed, user }

class TaskItem {
  final TaskItemKind kind;
  final String orderKey;
  final int sortOrder;
  final PrayerBlock? prayerBlock;
  final FixedTask? fixedTask;
  final UserTaskInstance? userTask;

  const TaskItem._({
    required this.kind,
    required this.orderKey,
    required this.sortOrder,
    this.prayerBlock,
    this.fixedTask,
    this.userTask,
  });

  factory TaskItem.prayer(PrayerBlock block) => TaskItem._(
        kind: TaskItemKind.prayer,
        orderKey: 'prayer',
        sortOrder: block.sortOrder,
        prayerBlock: block,
      );

  factory TaskItem.fixed(FixedTask task) => TaskItem._(
        kind: TaskItemKind.fixed,
        orderKey: task.taskType.name,
        sortOrder: task.sortOrder,
        fixedTask: task,
      );

  factory TaskItem.user(UserTaskInstance task) => TaskItem._(
        kind: TaskItemKind.user,
        orderKey: 'user:${task.id}',
        sortOrder: task.sortOrder,
        userTask: task,
      );

  String get widgetKey => switch (kind) {
        TaskItemKind.prayer => 'prayer:${prayerBlock!.id}',
        TaskItemKind.fixed => 'fixed:${fixedTask!.id}',
        TaskItemKind.user => 'user:${userTask!.id}',
      };
}

class BlockView {
  final PrayerBlock block;
  final List<FixedTask> fixedTasks;
  final List<UserTaskInstance> userTasks;

  const BlockView({
    required this.block,
    required this.fixedTasks,
    required this.userTasks,
  });

  List<TaskItem> get orderedItems {
    final items = <TaskItem>[
      TaskItem.prayer(block),
      for (final task in fixedTasks) TaskItem.fixed(task),
      for (final task in userTasks) TaskItem.user(task),
    ];
    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return items;
  }
}

class DailyViewData {
  final Day day;
  final Map<PrayerType, BlockView> blocksByType;

  const DailyViewData({required this.day, required this.blocksByType});

  List<BlockView> get orderedBlocks => [
        blocksByType[PrayerType.fajr]!,
        blocksByType[PrayerType.dhuhr]!,
        blocksByType[PrayerType.asr]!,
        blocksByType[PrayerType.maghrib]!,
        blocksByType[PrayerType.isha]!,
      ];
}