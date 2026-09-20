import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../domain/feedback_engine.dart';
import '../../prayer_blocks/view_models/today_notifier.dart';

class DashboardData {
  final double consistencyValue;
  final FeedbackResult feedback;

  const DashboardData({
    required this.consistencyValue,
    required this.feedback,
  });
}

class DashboardNotifier extends AsyncNotifier<DashboardData> {
  @override
  Future<DashboardData> build() async {
    ref.watch(todayNotifierProvider);

    final today = DateTime.now();

    final consistencyValue = await ref
        .read(consistencyRepositoryProvider)
        .calculateCurrentConsistency(asOf: today);

    final feedback = await ref
        .read(feedbackRepositoryProvider)
        .generateCurrentFeedback(asOf: today);

    return DashboardData(
      consistencyValue: consistencyValue,
      feedback: feedback,
    );
  }
}

final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardData>(
  DashboardNotifier.new,
);