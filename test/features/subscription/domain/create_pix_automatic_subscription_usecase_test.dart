import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vita_clube/core/error/failures.dart';
import 'package:vita_clube/features/home/domain/entities/plan_level.dart';
import 'package:vita_clube/features/subscription/domain/entities/subscription_entity.dart';
import 'package:vita_clube/features/subscription/domain/entities/subscription_status.dart';
import 'package:vita_clube/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:vita_clube/features/subscription/domain/usecases/create_pix_automatic_subscription_usecase.dart';

import '../../../helpers/test_helpers.dart';

class _FakePixCustomer extends Fake implements PixAutomaticCustomer {}

void main() {
  late MockSubscriptionRepository repository;
  late CreatePixAutomaticSubscriptionUseCase useCase;

  setUpAll(() {
    registerFallbackValue(_FakePixCustomer());
  });

  setUp(() {
    repository = MockSubscriptionRepository();
    useCase = CreatePixAutomaticSubscriptionUseCase(repository);
  });

  const customer = PixAutomaticCustomer(
    name: 'Maria Silva',
    taxId: '12345678901',
    email: 'maria@email.com',
    phone: '5585999999999',
    address: PixAutomaticBillingAddress(
      zipcode: '60160000',
      street: 'Rua A',
      number: '123',
      neighborhood: 'Centro',
      city: 'Fortaleza',
      state: 'CE',
    ),
  );

  final subscription = SubscriptionEntity(
    id: 'sub_1',
    userId: 'user_1',
    planId: 'vittaclube-monthly',
    level: PlanLevel.bronze,
    activationDate: DateTime(2026, 6, 2),
    expirationDate: DateTime(2026, 7, 2),
    isCurrent: true,
    pixStatus: PixAutomaticSubscriptionStatus.waitingAuthorization,
    paymentLinkUrl: 'https://woovi.com/subscription/auth/abc',
  );

  test('delegates Pix Automatic subscription creation to repository', () async {
    when(
      () => repository.createPixAutomaticSubscription(
        planId: any(named: 'planId'),
        customer: any(named: 'customer'),
      ),
    ).thenAnswer((_) async => Right(subscription));

    final result = await useCase(
      CreatePixAutomaticSubscriptionParams(
        planId: 'vittaclube-monthly',
        customer: customer,
      ),
    );

    expect(result, Right(subscription));
    verify(
      () => repository.createPixAutomaticSubscription(
        planId: 'vittaclube-monthly',
        customer: customer,
      ),
    ).called(1);
    verifyNoMoreInteractions(repository);
  });

  test('returns repository failure without swallowing the error', () async {
    when(
      () => repository.createPixAutomaticSubscription(
        planId: any(named: 'planId'),
        customer: any(named: 'customer'),
      ),
    ).thenAnswer(
      (_) async => const Left(ServerFailure('Woovi indisponível.')),
    );

    final result = await useCase(
      CreatePixAutomaticSubscriptionParams(
        planId: 'vittaclube-monthly',
        customer: customer,
      ),
    );

    expect(result, isA<Left<Failure, SubscriptionEntity>>());
    result.fold(
      (failure) => expect(failure.message, 'Woovi indisponível.'),
      (_) => fail('Expected failure'),
    );
  });

  test('requires a complete billing address for Pix Automatic customer', () {
    expect(customer.address.isComplete, isTrue);
    expect(customer.isComplete, isTrue);

    const incomplete = PixAutomaticBillingProfile(
      name: 'Maria Silva',
      taxId: '12345678901',
      email: 'maria@email.com',
      phone: '5585999999999',
      address: PixAutomaticBillingAddress(
        zipcode: '60160000',
        street: 'Rua A',
        number: '',
        neighborhood: 'Centro',
        city: 'Fortaleza',
        state: 'CE',
      ),
    );

    expect(incomplete.isComplete, isFalse);
  });
}
