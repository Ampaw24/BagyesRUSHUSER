import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/consumer_notification.dart';
import '../repositories/i_consumer_notification_repository.dart';
import '../repositories/consumer_notification_repository_impl.dart';

// ─── Repository provider ─────────────────────────────────────────────────────

final consumerNotificationRepositoryProvider =
    Provider<IConsumerNotificationRepository>(
  (_) => ConsumerNotificationRepositoryImpl(),
);

// ─── State ───────────────────────────────────────────────────────────────────

class ConsumerNotificationState {
  final List<ConsumerNotification> notifications;
  final bool isLoading;

  const ConsumerNotificationState({
    this.notifications = const [],
    this.isLoading = false,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  ConsumerNotificationState copyWith({
    List<ConsumerNotification>? notifications,
    bool? isLoading,
  }) =>
      ConsumerNotificationState(
        notifications: notifications ?? this.notifications,
        isLoading: isLoading ?? this.isLoading,
      );
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class ConsumerNotificationNotifier
    extends StateNotifier<ConsumerNotificationState> {
  final IConsumerNotificationRepository _repository;

  ConsumerNotificationNotifier(this._repository)
      : super(const ConsumerNotificationState(isLoading: true)) {
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

final consumerNotificationProvider = StateNotifierProvider<
    ConsumerNotificationNotifier, ConsumerNotificationState>((ref) {
  final repo = ref.read(consumerNotificationRepositoryProvider);
  return ConsumerNotificationNotifier(repo);
});
