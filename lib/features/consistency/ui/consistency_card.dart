import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../view_models/dashboard_notifier.dart';

class ConsistencyCard extends ConsumerWidget {
  const ConsistencyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final data = dashboardAsync.hasValue ? dashboardAsync.value : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Builder(
          builder: (context) {
            if (data == null) {
              if (dashboardAsync.hasError) {
                return Text(
                  'Could not load dashboard: ${dashboardAsync.error}',
                );
              }
              return const SizedBox(
                height: 60,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Consistency',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  '${data.consistencyValue.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  data.feedback.mainMessage,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (data.feedback.supportingStat != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    data.feedback.supportingStat!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}