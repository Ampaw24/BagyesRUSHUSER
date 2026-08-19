import 'package:equatable/equatable.dart';
import 'package:bagyesrushappusernew/core/errors/failure.dart';
import 'package:bagyesrushappusernew/src/notification/model/notification.model.dart';

sealed class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

final class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

final class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

final class NotificationsLoaded extends NotificationState {
  const NotificationsLoaded(this.notifications);

  final List<NotificationModel> notifications;

  @override
  List<Object?> get props => [notifications];
}

final class UnreadCountLoaded extends NotificationState {
  const UnreadCountLoaded(this.count);

  final int count;

  @override
  List<Object?> get props => [count];
}

final class NotificationMarkedRead extends NotificationState {
  const NotificationMarkedRead(this.notification);

  final NotificationModel notification;

  @override
  List<Object?> get props => [notification];
}

final class AllNotificationsMarkedRead extends NotificationState {
  const AllNotificationsMarkedRead();
}

final class NotificationDeleted extends NotificationState {
  const NotificationDeleted(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

final class NotificationError extends NotificationState {
  const NotificationError({required this.message, required this.title});

  NotificationError.fromFailure(Failure failure)
      : this(message: failure.message, title: failure.title);

  final String message;
  final String title;

  @override
  List<Object?> get props => [message, title];
}
