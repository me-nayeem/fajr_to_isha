const int locationRefreshIntervalDays = 30;


bool shouldAutoRefreshLocation({
  required DateTime? lastCheckedAt,
  required DateTime now,
}) {
  if (lastCheckedAt == null) return true;
  return now.difference(lastCheckedAt).inDays >= locationRefreshIntervalDays;
}