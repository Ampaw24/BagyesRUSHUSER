import 'package:bagyesrushappusernew/src/chat/model/chat_message.dart';

/// Consecutive messages from the same side within this window render as one
/// visual group (tight spacing, joined corners).
const Duration messageGroupWindow = Duration(minutes: 5);

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
];

bool isSameChatDay(DateTime a, DateTime b) {
  final la = a.toLocal();
  final lb = b.toLocal();
  return la.year == lb.year && la.month == lb.month && la.day == lb.day;
}

/// Whether [a] and [b] (adjacent in the thread) belong to the same bubble
/// group: same side, same sender, same day and close together in time.
bool isSameMessageGroup(ChatMessage a, ChatMessage b) =>
    a.isMine == b.isMine &&
    a.sender.id == b.sender.id &&
    isSameChatDay(a.createdAt, b.createdAt) &&
    a.createdAt.difference(b.createdAt).abs() <= messageGroupWindow;

/// "Today", "Yesterday", "Mon, 28 Sep", or "Mon, 28 Sep 2025" for another
/// year — the label on the day separator above a day's first message.
String chatDayLabel(DateTime date, {DateTime? now}) {
  final local = date.toLocal();
  final today = now ?? DateTime.now();
  final days = DateTime.utc(today.year, today.month, today.day)
      .difference(DateTime.utc(local.year, local.month, local.day))
      .inDays;
  if (days == 0) return 'Today';
  if (days == 1) return 'Yesterday';
  final label =
      '${_weekdays[local.weekday - 1]}, ${local.day} ${_months[local.month - 1]}';
  return local.year == today.year ? label : '$label ${local.year}';
}
