import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../domain/daily_view_data.dart';
import '../../../shared/labels.dart';
import '../view_models/today_notifier.dart';
import 'add_task_sheet.dart';

class BlockCard extends ConsumerWidget {
  final BlockView block;

  const BlockCard({super.key, required this.block});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(todayNotifierProvider.notifier);
    final timeLabel = DateFormat('h:mm a').format(block.block.scheduledTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    prayerTypeLabel(block.block.prayerType),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    timeLabel,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            CheckboxListTile(
              controlAffinity: ListTileControlAffinity.leading,
              title: Text('Pray ${prayerTypeLabel(block.block.prayerType)}'),
              value: block.block.prayerCompleted,
              onChanged: (value) {
                notifier.togglePrayer(block.block.id, value ?? false);
              },
            ),
            for (final fixedTask in block.fixedTasks)
              CheckboxListTile(
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(fixedTaskLabel(fixedTask.taskType)),
                value: fixedTask.completed,
                onChanged: (value) {
                  notifier.toggleFixedTask(fixedTask.id, value ?? false);
                },
              ),
            for (final userTask in block.userTasks)
              CheckboxListTile(
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(userTask.title),
                value: userTask.completed,
                onChanged: (value) {
                  notifier.toggleUserTask(userTask.id, value ?? false);
                },
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => AddTaskSheet(
                      prayerBlockType: block.block.prayerType,
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add task'),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}