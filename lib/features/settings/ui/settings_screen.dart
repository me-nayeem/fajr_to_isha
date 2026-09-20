import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/theme.dart';
import '../../../data/local/database.dart';
import '../../../data/services/location_service.dart';
import '../../prayer_blocks/view_models/today_notifier.dart';
import '../view_models/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Could not load settings: $error')),
        data: (settings) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _SectionHeader('Prayer Calculation'),
              _SettingsCard(
                children: [
                  const _StaticRow(
                    icon: Icons.calculate_outlined,
                    title: 'Calculation Method',
                    subtitle: 'Muslim World League',
                    trailing: _Tag(label: 'Default'),
                  ),
                  const Divider(height: 1),
                  _MadhabRow(currentMadhab: settings.madhab),
                ],
              ),
              const SizedBox(height: 24),
              const _SectionHeader('Location & Prayer Times'),
              _SettingsCard(
                children: [
                  _LocationRow(settings: settings),
                  if (settings.locationLat == null) ...[
                    const Divider(height: 1),
                    _ManualPrayerTimesSection(settings: settings),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              const _SectionHeader('Notifications'),
              _SettingsCard(
                children: [
                  _NotificationTimeRow(settings: settings),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(children: children),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;

  const _IconBadge(this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: AppColors.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: AppColors.primary),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;

  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Default',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _StaticRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _StaticRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _IconBadge(icon),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: trailing,
    );
  }
}

class _MadhabRow extends ConsumerWidget {
  final String currentMadhab;

  const _MadhabRow({required this.currentMadhab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const _IconBadge(Icons.mosque_outlined),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Madhab (Asr timing)',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'shafi', label: Text("Shafi'i")),
              ButtonSegment(value: 'hanafi', label: Text('Hanafi')),
            ],
            selected: {currentMadhab},
            onSelectionChanged: (selection) async {
              await ref
                  .read(settingsRepositoryProvider)
                  .updateMadhab(selection.first);
              ref.invalidate(settingsProvider);
            },
          ),
        ],
      ),
    );
  }
}

class _LocationRow extends ConsumerWidget {
  final AppSettings settings;

  const _LocationRow({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasLocation = settings.locationLat != null;

    return ListTile(
      leading: _IconBadge(
        hasLocation ? Icons.location_on_outlined : Icons.location_off_outlined,
      ),
      title: Text(
        hasLocation ? 'Location set' : 'Location not set',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      subtitle: Text(
        hasLocation
            ? 'Prayer times are calculated automatically'
            : 'Enable location for automatic prayer times',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: TextButton(
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
            ref.invalidate(settingsProvider);
            ref.invalidate(todayNotifierProvider);
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not access location')),
            );
          }
        },
        child: Text(hasLocation ? 'Update' : 'Enable'),
      ),
    );
  }
}

class _ManualPrayerTimesSection extends ConsumerStatefulWidget {
  final AppSettings settings;

  const _ManualPrayerTimesSection({required this.settings});

  @override
  ConsumerState<_ManualPrayerTimesSection> createState() =>
      _ManualPrayerTimesSectionState();
}

class _ManualPrayerTimesSectionState
    extends ConsumerState<_ManualPrayerTimesSection> {
  final Map<String, TimeOfDay> _times = {
    'fajr': const TimeOfDay(hour: 5, minute: 0),
    'dhuhr': const TimeOfDay(hour: 12, minute: 15),
    'asr': const TimeOfDay(hour: 15, minute: 45),
    'maghrib': const TimeOfDay(hour: 18, minute: 20),
    'isha': const TimeOfDay(hour: 19, minute: 45),
  };

  static const _labels = {
    'fajr': 'Fajr',
    'dhuhr': 'Dhuhr',
    'asr': 'Asr',
    'maghrib': 'Maghrib',
    'isha': 'Isha',
  };

  Future<void> _pickTime(String key) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _times[key]!,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _times[key] = picked);
    }
  }

  String _encodeJson(Map<String, String> map) {
    final entries =
        map.entries.map((e) => '"${e.key}":"${e.value}"').join(',');
    return '{$entries}';
  }

  Future<void> _save() async {
    final map = _times.map(
      (key, value) => MapEntry(
        key,
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
      ),
    );
    await ref
        .read(settingsRepositoryProvider)
        .updateManualPrayerTimes(_encodeJson(map));
    ref.invalidate(settingsProvider);
    ref.invalidate(todayNotifierProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Manual prayer times saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manual Prayer Times',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Used since no location is set',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          for (final key in _labels.keys)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_labels[key]!),
              trailing: Text(_times[key]!.format(context)),
              onTap: () => _pickTime(key),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              child: const Text('Save Manual Times'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTimeRow extends ConsumerWidget {
  final AppSettings settings;

  const _NotificationTimeRow({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parts = settings.notificationTime.split(':');
    final currentTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    return ListTile(
      leading: const _IconBadge(Icons.notifications_outlined),
      title: Text(
        'Daily reminder time',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      subtitle: Text(
        currentTime.format(context),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: currentTime,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          ),
        );
        if (picked == null) return;

        final hhmm =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';

        await ref
            .read(settingsRepositoryProvider)
            .updateNotificationTime(hhmm);
        await ref
            .read(notificationServiceProvider)
            .scheduleDailyReminder(picked.hour, picked.minute);
        ref.invalidate(settingsProvider);
      },
    );
  }
}