import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import 'package:bagyesrushappusernew/src/notification/repository/notification_repository.dart';
import 'package:bagyesrushappusernew/src/notification/viewmodel/notification_state.dart';

class NotificationViewmodel extends ViewModel<NotificationState> {
  NotificationViewmodel({required NotificationRepository repository})
      : _repository = repository,
        super(const NotificationInitial());

  final NotificationRepository _repository;

  /// Live unread badge count. Deliberately kept independent of [state]:
  /// [state] is a one-shot sealed value that gets reset after every screen
  /// action (see [resetState]), but badges elsewhere in the app (bell icons,
  /// drawer rows) share this same ViewModel instance and must keep showing
  /// a stable count regardless of what the notification screen is doing.
  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  // ─── List ──────────────────────────────────────────────────────────────────

  Future<void> getNotifications({bool? unread, int? perPage}) async {
    appLogger.d(
        'NotificationViewmodel.getNotifications → unread=$unread, perPage=$perPage');
    emit(const NotificationLoading());

    final result =
        await _repository.getNotifications(unread: unread, perPage: perPage);

    result.fold(
      (failure) {
        appLogger.w(
            'NotificationViewmodel.getNotifications → error: ${failure.message}');
        emit(NotificationError.fromFailure(failure));
      },
      (notifications) {
        appLogger.i(
            'NotificationViewmodel.getNotifications → loaded ${notifications.length} notifications');
        _unreadCount = notifications.where((n) => !n.isRead).length;
        emit(NotificationsLoaded(notifications));
      },
    );
  }

  // ─── Unread Count ──────────────────────────────────────────────────────────

  Future<void> getUnreadCount() async {
    appLogger.d('NotificationViewmodel.getUnreadCount → initiated');
    emit(const NotificationLoading());

    final result = await _repository.getUnreadCount();

    result.fold(
      (failure) {
        appLogger.w(
            'NotificationViewmodel.getUnreadCount → error: ${failure.message}');
        emit(NotificationError.fromFailure(failure));
      },
      (count) {
        appLogger.i('NotificationViewmodel.getUnreadCount → count=$count');
        _unreadCount = count;
        emit(UnreadCountLoaded(count));
      },
    );
  }

  // ─── Mark as read ──────────────────────────────────────────────────────────

  Future<void> markAsRead(String id) async {
    appLogger.d('NotificationViewmodel.markAsRead → id=$id');
    emit(const NotificationLoading());
    final result = await _repository.markAsRead(id);
    result.fold(
      (failure) {
        appLogger.w(
            'NotificationViewmodel.markAsRead → error: ${failure.message}');
        emit(NotificationError.fromFailure(failure));
      },
      (notification) {
        appLogger.i('NotificationViewmodel.markAsRead → id=$id marked read');
        if (_unreadCount > 0) _unreadCount--;
        emit(NotificationMarkedRead(notification));
      },
    );
  }

  // ─── Mark all as read ──────────────────────────

  Future<void> markAllAsRead() async {
    appLogger.d('NotificationViewmodel.markAllAsRead → initiated');
    emit(const NotificationLoading());

    final result = await _repository.markAllAsRead();

    result.fold(
      (failure) {
        appLogger.w(
            'NotificationViewmodel.markAllAsRead → error: ${failure.message}');
        emit(NotificationError.fromFailure(failure));
      },
      (_) {
        appLogger.i('NotificationViewmodel.markAllAsRead → success');
        _unreadCount = 0;
        emit(const AllNotificationsMarkedRead());
      },
    );
  }

  // ─── Delete ────────────────────────────────────────────────────────────────

  /// [wasUnread] lets the caller (which holds the on-screen list) tell the
  /// badge whether the deleted notification counted toward [unreadCount] —
  /// the delete endpoint returns no body to infer that from.
  Future<void> deleteNotification(String id, {bool wasUnread = false}) async {
    appLogger.d('NotificationViewmodel.deleteNotification → id=$id');
    emit(const NotificationLoading());

    final result = await _repository.deleteNotification(id);

    result.fold(
      (failure) {
        appLogger.w(
            'NotificationViewmodel.deleteNotification → error: ${failure.message}');
        emit(NotificationError.fromFailure(failure));
      },
      (_) {
        appLogger.i('NotificationViewmodel.deleteNotification → id=$id deleted');
        if (wasUnread && _unreadCount > 0) _unreadCount--;
        emit(NotificationDeleted(id));
      },
    );
  }

  /// Resets state to [NotificationInitial] after a one-shot action has been
  /// handled.
  void resetState() => emit(const NotificationInitial());
}
