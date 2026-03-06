import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vendor_notification.dart';
import '../repositories/i_notification_repository.dart';
import '../repositories/notification_repository_impl.dart';

// ─── Repository provider (DI via Riverpod) ──────────────────────────────────

final notificationRepositoryProvider = Provider<INotificationRepository>(
  (_) => NotificationRepositoryImpl(),
);

// ─── State ───────────────────────────────────────────────────────────────────

class NotificationState {
  final List<VendorNotification> notifications;
  final bool isLoading;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationState copyWith({
    List<VendorNotification>? notifications,
    bool? isLoading,
  }) =>
      NotificationState(
        notifications: notifications ?? this.notifications,
        isLoading: isLoading ?? this.isLoading,
      );
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class NotificationNotifier extends StateNotifier<NotificationState> {
  final INotificationRepository _repository;

  NotificationNotifier(this._repository)
      : super(const NotificationState(isLoading: true)) {
    _load();
  }

  void _load() {
    final items = _repository.getNotifications();
    state = state.copyWith(notifications: items, isLoading: false);
  }

  void markRead(String id) {
    final updated = _repository.markAsRead(state.notifications, id);
    state = state.copyWith(notifications: updated);
  }

  void markAllRead() {
    final updated = _repository.markAllAsRead(state.notifications);
    state = state.copyWith(notifications: updated);
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final repo = ref.read(notificationRepositoryProvider);
  return NotificationNotifier(repo);
});
