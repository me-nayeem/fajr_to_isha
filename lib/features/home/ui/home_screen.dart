import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../data/local/tables.dart';
import '../../../data/services/location_service.dart';
import '../../../domain/daily_view_data.dart';
import '../../../domain/next_prayer.dart';
import '../../../shared/labels.dart';
import '../../../app/providers.dart';
import '../../consistency/ui/consistency_card.dart';
import '../../history/ui/history_screen.dart';
import '../../prayer_blocks/ui/add_task_sheet.dart';
import '../../prayer_blocks/view_models/today_notifier.dart';
import '../../settings/view_models/settings_provider.dart';
import 'walking_progress_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayNotifierProvider);

    return SafeArea(
      child: todayAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Something went wrong loading today:\n$error'),
          ),
        ),
        data: (state) {
          if (state is TodayNeedsSetup) {
            return const _NeedsSetupView();
          }
          final ready = state as TodayReady;
          return _HomeContent(data: ready.data);
        },
      ),
    );
  }
}

class _HomeContent extends ConsumerStatefulWidget {
  final DailyViewData data;

  const _HomeContent({required this.data});

  @override
  ConsumerState<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends ConsumerState<_HomeContent> {
  late PrayerType _selectedType;
  bool _initialized = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _selectTab(PrayerType type) {
    final preservedOffset =
        _scrollController.hasClients ? _scrollController.offset : 0.0;
    setState(() => _selectedType = type);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = preservedOffset.clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.jumpTo(target);
    });
  }

  void _selectDefaultTab() {
    final entries = widget.data.orderedBlocks
        .map((b) => PrayerTimeEntry(
              type: b.block.prayerType,
              time: b.block.scheduledTime,
            ))
        .toList();
    _selectedType = determineNextPrayer(entries, DateTime.now()).current;
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      _selectDefaultTab();
      _initialized = true;
    }

    final blocks = widget.data.orderedBlocks;

    var completedCount = 0;
    var totalCount = 0;
    for (final block in blocks) {
      totalCount += 1;
      if (block.block.prayerCompleted) completedCount += 1;
      for (final fixedTask in block.fixedTasks) {
        totalCount += 1;
        if (fixedTask.completed) completedCount += 1;
      }
      for (final userTask in block.userTasks) {
        totalCount += 1;
        if (userTask.completed) completedCount += 1;
      }
    }

    final selectedBlock =
        blocks.firstWhere((b) => b.block.prayerType == _selectedType);

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Assalamu Alaikum',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('EEEE, MMMM d').format(DateTime.now()),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.history,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const ConsistencyCard(),
        const SizedBox(height: 12),
        WalkingProgressCard(completed: completedCount, total: totalCount),
        const SizedBox(height: 12),
        _PrayerTabsCard(
          blocks: blocks,
          selectedType: _selectedType,
          onSelect: _selectTab,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${prayerTypeLabel(_selectedType)} Tasks',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => AddTaskSheet(prayerBlockType: _selectedType),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Task'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _BlockTaskList(block: selectedBlock),
      ],
    );
  }
}

class _BlockTaskList extends ConsumerWidget {
  final BlockView block;

  const _BlockTaskList({required this.block});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = <Widget>[];

    if (!block.block.prayerCompleted) {
      rows.add(_TaskRow(
        title: 'Pray ${prayerTypeLabel(block.block.prayerType)}',
        leading: const Icon(Icons.mosque_outlined, color: AppColors.primary),
        tagLabel: 'Prayer',
        tagColor: AppColors.primary,
        completed: false,
        onToggle: (value) {
          if (value) _celebrate(context);
          ref
              .read(todayNotifierProvider.notifier)
              .togglePrayer(block.block.id, value);
        },
      ));
    }

    for (final fixedTask in block.fixedTasks) {
      if (fixedTask.completed) continue;
      rows.add(_TaskRow(
        title: fixedTaskLabel(fixedTask.taskType),
        leading: Icon(
          _iconForFixedTask(fixedTask.taskType),
          color: AppColors.primary,
        ),
        tagLabel: 'Fixed',
        tagColor: AppColors.onSurfaceVariant,
        completed: false,
        onToggle: (value) {
          if (value) _celebrate(context);
          ref
              .read(todayNotifierProvider.notifier)
              .toggleFixedTask(fixedTask.id, value);
        },
      ));
    }

    for (final userTask in block.userTasks) {
      if (userTask.completed) continue;
      rows.add(_TaskRow(
        title: userTask.title,
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryContainer,
          child: Text(
            userTask.title.isNotEmpty ? userTask.title[0].toUpperCase() : '?',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        tagLabel: 'Personal',
        tagColor: AppColors.primary,
        completed: false,
        onToggle: (value) {
          if (value) _celebrate(context);
          ref
              .read(todayNotifierProvider.notifier)
              .toggleUserTask(userTask.id, value);
        },
      ));
    }

    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Everything here is done.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  void _celebrate(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Nice work!'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  IconData _iconForFixedTask(FixedTaskType type) {
    switch (type) {
      case FixedTaskType.quranAfterFajr:
        return Icons.menu_book;
      case FixedTaskType.personalTimeAfterAsr:
        return Icons.self_improvement;
      case FixedTaskType.quranAfterIsha:
        return Icons.menu_book;
      case FixedTaskType.sleepAfterIsha:
        return Icons.bedtime;
    }
  }
}

class _TaskRow extends StatelessWidget {
  final String title;
  final Widget leading;
  final String tagLabel;
  final Color tagColor;
  final bool completed;
  final void Function(bool) onToggle;

  const _TaskRow({
    required this.title,
    required this.leading,
    required this.tagLabel,
    required this.tagColor,
    required this.completed,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: leading,
        title: Text(title),
        subtitle: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: tagColor == AppColors.primary
                  ? AppColors.primaryContainer
                  : const Color(0xFFE9EEEB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tagLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: tagColor,
              ),
            ),
          ),
        ),
        trailing: Checkbox(
          value: completed,
          onChanged: (value) => onToggle(value ?? false),
        ),
        onTap: () => onToggle(!completed),
      ),
    );
  }
}

class _PrayerTabsCard extends StatelessWidget {
  final List<BlockView> blocks;
  final PrayerType selectedType;
  final void Function(PrayerType) onSelect;

  const _PrayerTabsCard({
    required this.blocks,
    required this.selectedType,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            for (final block in blocks)
              Expanded(
                child: _PrayerTab(
                  block: block,
                  isSelected: block.block.prayerType == selectedType,
                  onTap: () => onSelect(block.block.prayerType),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PrayerTab extends StatelessWidget {
  final BlockView block;
  final bool isSelected;
  final VoidCallback onTap;

  const _PrayerTab({
    required this.block,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          children: [
            Text(
              prayerTypeLabel(block.block.prayerType),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat.jm().format(block.block.scheduledTime),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _NeedsSetupView extends ConsumerWidget {
  const _NeedsSetupView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'FajrToIsha needs your location to calculate accurate '
              'prayer times, or you can set manual times in Settings.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final locationService = ref.read(locationServiceProvider);
                final settingsRepo = ref.read(settingsRepositoryProvider);

                final result = await locationService.getCurrentCoordinates(
                  requestIfDenied: true,
                );

                if (result is LocationAvailable) {
                  await settingsRepo.updateLocation(
                    latitude: result.coordinates.latitude,
                    longitude: result.coordinates.longitude,
                  );
                  ref.invalidate(todayNotifierProvider);
                  ref.invalidate(settingsProvider);
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not access location')),
                  );
                }
              },
              child: const Text('Enable Location'),
            ),
          ],
        ),
      ),
    );
  }
}