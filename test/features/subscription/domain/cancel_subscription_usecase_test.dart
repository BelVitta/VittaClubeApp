import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vita_clube/core/error/failures.dart';
import 'package:vita_clube/features/subscription/domain/usecases/cancel_subscription_usecase.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late MockSubscriptionRepository repository;
  late CancelSubscriptionUseCase useCase;

  setUp(() {
    repository = MockSubscriptionRepository();
    useCase = CancelSubscriptionUseCase(repository);
  });

  test('delegates cancellation to repository with reason', () async {
    when(
      () => repository.cancelSubscription(
        subscriptionId: any(named: 'subscriptionId'),
        reason: any(named: 'reason'),
      ),
    ).thenAnswer((_) async => const Right(null));

    final result = await useCase(
      subscriptionId: 'sub_1',
      reason: 'Solicitado pelo operador',
    );

    expect(result, const Right(null));
    verify(
      () => repository.cancelSubscription(
        subscriptionId: 'sub_1',
        reason: 'Solicitado pelo operador',
      ),
    ).called(1);
    verifyNoMoreInteractions(repository);
  });

  test('returns repository failure', () async {
    when(
      () => repository.cancelSubscription(
        subscriptionId: any(named: 'subscriptionId'),
        reason: any(named: 'reason'),
      ),
    ).thenAnswer(
      (_) async => const Left(AuthFailure('Sem permissão.')),
    );

    final result = await useCase(subscriptionId: 'sub_1');

    expect(result, isA<Left<Failure, void>>());
  });
}
