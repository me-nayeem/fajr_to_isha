import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/local/tables.dart';
import '../../../shared/labels.dart';
import '../view_models/today_notifier.dart';

class AddTaskSheet extends ConsumerStatefulWidget {
  final PrayerType prayerBlockType;

  const AddTaskSheet({super.key, required this.prayerBlockType});

  @override
  ConsumerState<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<AddTaskSheet> {
  final _titleController = TextEditingController();
  late PrayerType _selectedBlock = widget.prayerBlockType;
  DateTime _taskDate = DateTime.now();
  String? _errorText;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _taskDate,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() => _taskDate = picked);
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _errorText = 'Please enter a task title.');
      return;
    }

    ref.read(todayNotifierProvider.notifier).addTask(
          title: title,
          prayerBlockType: _selectedBlock,
          recurrenceType: RecurrenceType.once,
          specificDate: _taskDate,
          startDate: null,
          endDate: null,
          weekdays: null,
        );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Task',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PrayerType>(
              value: _selectedBlock,
              decoration: const InputDecoration(labelText: 'Prayer block'),
              items: [
                for (final type in PrayerType.values)
                  DropdownMenuItem(
                    value: type,
                    child: Text(prayerTypeLabel(type)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _selectedBlock = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Task title'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(DateFormat.yMMMd().format(_taskDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: const Text('Add Task'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}