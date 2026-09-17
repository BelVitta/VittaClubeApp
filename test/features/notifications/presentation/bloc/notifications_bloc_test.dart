import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vita_clube/core/error/failures.dart';
import 'package:vita_clube/features/notifications/domain/entities/notification_entity.dart';
import 'package:vita_clube/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:vita_clube/features/notifications/domain/usecases/get_unread_count_usecase.dart';
import 'package:vita_clube/features/notifications/domain/usecases/mark_all_notifications_read_usecase.dart';
import 'package:vita_clube/features/notifications/domain/usecases/mark_notification_read_usecase.dart';
import 'package:vita_clube/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:vita_clube/features/notifications/presentation/bloc/notifications_event.dart';
import 'package:vita_clube/features/notifications/presentation/bloc/notifications_state.dart';

class MockGetNotificationsUseCase extends Mock
    implements GetNotificationsUseCase {}

class MockGetUnreadCountUseCase extends Mock implements GetUnreadCountUseCase {}

class MockMarkNotificationReadUseCase extends Mock
    implements MarkNotificationReadUseCase {}

class MockMarkAllNotificationsReadUseCase extends Mock
    implements MarkAllNotificationsReadUseCase {}

void main() {
  late NotificationsBloc bloc;
  late MockGetNotificationsUseCase mockGet;
  late MockGetUnreadCountUseCase mockUnread;
  late MockMarkNotificationReadUseCase mockMarkRead;
  late MockMarkAllNotificationsReadUseCase mockMarkAll;

  final tNow = DateTime.parse('2026-09-07T12:00:00Z');
  final tUnread = NotificationEntity(
    id: '1',
    title: 'Nova nutricionista',
    body: 'Dra. Ana atende esta semana.',
    type: 'profissional',
    isRead: false,
    createdAt: tNow,
  );
  final tRead = tUnread.copyWith(isRead: true, readAt: tNow);

  setUp(() {
    mockGet = MockGetNotificationsUseCase();
    mockUnread = MockGetUnreadCountUseCase();
    mockMarkRead = MockMarkNotificationReadUseCase();
    mockMarkAll = MockMarkAllNotificationsReadUseCase();
    bloc = NotificationsBloc(
      getNotificationsUseCase: mockGet,
      getUnreadCountUseCase: mockUnread,
      markNotificationReadUseCase: mockMarkRead,
      markAllNotificationsReadUseCase: mockMarkAll,
    );
  });

  tearDown(() => bloc.close());

  test('estado inicial vazio', () {
    expect(bloc.state.status, NotificationsStatus.initial);
    expect(bloc.state.items, isEmpty);
    expect(bloc.state.unreadCount, 0);
  });

  blocTest<NotificationsBloc, NotificationsState>(
    'LoadNotifications emite [loading, loaded] com unreadCount',
    build: () {
      when(() => mockGet()).thenAnswer((_) async => Right([tUnread]));
      return bloc;
    },
    act: (b) => b.add(const LoadNotifications()),
    expect: () => [
      isA<NotificationsState>()
          .having((s) => s.status, 'status', NotificationsStatus.loading),
      isA<NotificationsState>()
          .having((s) => s.status, 'status', NotificationsStatus.loaded)
          .having((s) => s.items, 'items', [tUnread]).having(
              (s) => s.unreadCount, 'unreadCount', 1),
    ],
  );

  blocTest<NotificationsBloc, NotificationsState>(
    'LoadNotifications emite [loading, failure] quando o usecase falha',
    build: () {
      when(() => mockGet()).thenAnswer(
        (_) async => const Left(ServerFailure('falhou')),
      );
      return bloc;
    },
    act: (b) => b.add(const LoadNotifications()),
    expect: () => [
      isA<NotificationsState>()
          .having((s) => s.status, 'status', NotificationsStatus.loading),
      isA<NotificationsState>()
          .having((s) => s.status, 'status', NotificationsStatus.failure)
          .having((s) => s.errorMessage, 'error', 'falhou'),
    ],
  );

  blocTest<NotificationsBloc, NotificationsState>(
    'MarkNotificationReadRequested zera o item e o unreadCount',
    build: () {
      when(() => mockMarkRead('1')).thenAnswer((_) async => const Right(null));
      return bloc;
    },
    seed: () => NotificationsState(
      status: NotificationsStatus.loaded,
      items: [tUnread],
      unreadCount: 1,
    ),
    act: (b) => b.add(const MarkNotificationReadRequested('1')),
    expect: () => [
      isA<NotificationsState>()
          .having((s) => s.unreadCount, 'unreadCount', 0)
          .having((s) => s.items.first.isRead, 'isRead', true),
    ],
    verify: (_) {
      verify(() => mockMarkRead('1')).called(1);
    },
  );

  blocTest<NotificationsBloc, NotificationsState>(
    'MarkAllNotificationsReadRequested zera unreadCount',
    build: () {
      when(() => mockMarkAll()).thenAnswer((_) async => const Right(null));
      return bloc;
    },
    seed: () => NotificationsState(
      status: NotificationsStatus.loaded,
      items: [tUnread, tRead],
      unreadCount: 1,
    ),
    act: (b) => b.add(const MarkAllNotificationsReadRequested()),
    expect: () => [
      isA<NotificationsState>().having((s) => s.unreadCount, 'unreadCount', 0),
    ],
  );
}
