/// "5m ago", "3h ago", "Yesterday", or "d/m/yyyy" for anything older.
String relativeTimeLabel(DateTime time, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(time);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  return '${time.day}/${time.month}/${time.year}';
}
