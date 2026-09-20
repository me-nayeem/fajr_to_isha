import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/local/database.dart';

final settingsProvider = FutureProvider<AppSettings>((ref) {
  return ref.read(settingsRepositoryProvider).getSettings();
});