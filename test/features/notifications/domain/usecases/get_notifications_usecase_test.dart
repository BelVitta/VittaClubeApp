import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vita_clube/core/error/failures.dart';
import 'package:vita_clube/features/notifications/domain/entities/notification_entity.dart';
import 'package:vita_clube/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:vita_clube/features/notifications/domain/usecases/get_notifications_usecase.dart';

class MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

void main() {
  late GetNotificationsUseCase useCase;
  late MockNotificationsRepository mockRepository;

  final tNow = DateTime.parse('2026-09-07T12:00:00Z');
  final tItems = [
    NotificationEntity(
      id: '1',
      title: 'Nova nutricionista',
      body: 'Dra. Ana atende esta semana.',
      type: 'profissional',
      isRead: false,
      createdAt: tNow,
      action: NotificationAction.professional,
      professionalId: 'p1',
      professionalName: 'Dra. Ana',
    ),
  ];

  setUp(() {
    mockRepository = MockNotificationsRepository();
    useCase = GetNotificationsUseCase(mockRepository);
  });

  test('retorna a lista quando o repositório sucede', () async {
    when(() => mockRepository.getForCurrentUser())
        .thenAnswer((_) async => Right(tItems));

    final result = await useCase();

    expect(result, Right(tItems));
    verify(() => mockRepository.getForCurrentUser()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('retorna ServerFailure quando o repositório falha', () async {
    when(() => mockRepository.getForCurrentUser()).thenAnswer(
      (_) async => const Left(ServerFailure('Erro ao buscar notificações')),
    );

    final result = await useCase();

    expect(result, const Left(ServerFailure('Erro ao buscar notificações')));
  });
}
