import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/subscription_entity.dart';
import '../repositories/subscription_repository.dart';

class CreatePixAutomaticSubscriptionParams {
  final String planId;
  final PixAutomaticCustomer customer;

  const CreatePixAutomaticSubscriptionParams({
    required this.planId,
    required this.customer,
  });
}

class CreatePixAutomaticSubscriptionUseCase {
  final SubscriptionRepository repository;

  const CreatePixAutomaticSubscriptionUseCase(this.repository);

  Future<Either<Failure, SubscriptionEntity>> call(
    CreatePixAutomaticSubscriptionParams params,
  ) {
    return repository.createPixAutomaticSubscription(
      planId: params.planId,
      customer: params.customer,
    );
  }
}
