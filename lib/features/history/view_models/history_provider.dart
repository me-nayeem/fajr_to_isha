import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/repositories/report_repository.dart';

final historyProvider = FutureProvider<List<DailyReportView>>((ref) {
  return ref.read(reportRepositoryProvider).getAllReports();
});