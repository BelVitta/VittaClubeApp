import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/get_unread_count_usecase.dart';
import '../../domain/usecases/mark_all_notifications_read_usecase.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final GetNotificationsUseCase getNotificationsUseCase;
  final GetUnreadCountUseCase getUnreadCountUseCase;
  final MarkNotificationReadUseCase markNotificationReadUseCase;
  final MarkAllNotificationsReadUseCase markAllNotificationsReadUseCase;

  NotificationsBloc({
    required this.getNotificationsUseCase,
    required this.getUnreadCountUseCase,
    required this.markNotificationReadUseCase,
    required this.markAllNotificationsReadUseCase,
  }) : super(const NotificationsState()) {
    on<LoadNotifications>(_onLoad);
    on<LoadUnreadCount>(_onUnreadCount);
    on<MarkNotificationReadRequested>(_onMarkRead);
    on<MarkAllNotificationsReadRequested>(_onMarkAllRead);
  }

  Future<void> _onLoad(
    LoadNotifications event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(status: NotificationsStatus.loading));
    final result = await getNotificationsUseCase();
    result.fold(
      (failure) => emit(state.copyWith(
        status: NotificationsStatus.failure,
        errorMessage: failure.message,
      )),
      (items) => emit(state.copyWith(
        status: NotificationsStatus.loaded,
        items: items,
        unreadCount: items.where((n) => !n.isRead).length,
      )),
    );
  }

  Future<void> _onUnreadCount(
    LoadUnreadCount event,
    Emitter<NotificationsState> emit,
  ) async {
    final result = await getUnreadCountUseCase();
    result.fold(
      (_) {},
      (count) => emit(state.copyWith(unreadCount: count)),
    );
  }

  Future<void> _onMarkRead(
    MarkNotificationReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    final result = await markNotificationReadUseCase(event.id);
    result.fold((_) {}, (_) {
      final items = state.items
          .map((n) => n.id == event.id
              ? n.copyWith(isRead: true, readAt: DateTime.now())
              : n)
          .toList();
      emit(state.copyWith(
        items: items,
        unreadCount: items.where((n) => !n.isRead).length,
      ));
    });
  }

  Future<void> _onMarkAllRead(
    MarkAllNotificationsReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    final result = await markAllNotificationsReadUseCase();
    result.fold((_) {}, (_) {
      final items = state.items
          .map((n) =>
              n.copyWith(isRead: true, readAt: n.readAt ?? DateTime.now()))
          .toList();
      emit(state.copyWith(items: items, unreadCount: 0));
    });
  }
}
