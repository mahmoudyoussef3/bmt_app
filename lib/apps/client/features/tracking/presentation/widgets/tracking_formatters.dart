// Pure display-string formatters shared by the tracking screen's cards, so
// each stays a small presentational widget instead of re-deriving labels.

String formatTrackingTime(DateTime? value) {
  if (value == null) return 'Pending';
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

String formatRelativeDeparture(DateTime? departure) {
  if (departure == null) return 'Scheduled time pending';
  final diff = departure.difference(DateTime.now());
  if (diff.inMinutes > 0) return 'Trip starts in ${diff.inMinutes} minutes';
  if (diff.inMinutes > -5) return 'Trip is starting now';
  return 'Scheduled trip';
}

String formatLiveLocationLabel(DateTime? updatedAt) {
  if (updatedAt == null) return 'Waiting for driver location';
  final diff = DateTime.now().difference(updatedAt);
  if (diff.inMinutes < 1) return 'Location sent just now';
  return 'Location sent ${diff.inMinutes} min ago';
}
