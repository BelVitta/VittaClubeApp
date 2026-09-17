import 'package:equatable/equatable.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationsEvent {
  const LoadNotifications();
}

class LoadUnreadCount extends NotificationsEvent {
  const LoadUnreadCount();
}

class MarkNotificationReadRequested extends NotificationsEvent {
  final String id;

  const MarkNotificationReadRequested(this.id);

  @override
  List<Object?> get props => [id];
}

class MarkAllNotificationsReadRequested extends NotificationsEvent {
  const MarkAllNotificationsReadRequested();
}
