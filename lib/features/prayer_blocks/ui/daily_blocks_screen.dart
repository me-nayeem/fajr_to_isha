import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/services/location_service.dart';
import '../../consistency/ui/consistency_card.dart';
import '../../history/ui/history_screen.dart';
import '../../learning/ui/learning_screen.dart';
import '../../settings/ui/settings_screen.dart';
import '../view_models/today_notifier.dart';
import 'block_card.dart';

class DailyBlocksScreen extends ConsumerWidget {
  const DailyBlocksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FajrToIsha'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LearningScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: todayAsync.when(
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
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const ConsistencyCard(),
              for (final block in ready.data.orderedBlocks)
                BlockCard(block: block),
            ],
          );
        },
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
            const Text(
              'FajrToIsha needs your location to calculate accurate '
              'prayer times for your area.',
              textAlign: TextAlign.center,
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
                } else if (context.mounted) {
                  final reason = (result as LocationUnavailable).reason;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Location unavailable: $reason')),
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