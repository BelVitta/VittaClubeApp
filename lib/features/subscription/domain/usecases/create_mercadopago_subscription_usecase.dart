import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/subscription_entity.dart';
import '../repositories/subscription_repository.dart';

class CreateMercadoPagoSubscriptionParams {
  final String planId;
  final String cardTokenId;

  const CreateMercadoPagoSubscriptionParams({
    required this.planId,
    required this.cardTokenId,
  });
}

class CreateMercadoPagoSubscriptionUseCase {
  final SubscriptionRepository repository;

  const CreateMercadoPagoSubscriptionUseCase(this.repository);

  Future<Either<Failure, SubscriptionEntity>> call(
    CreateMercadoPagoSubscriptionParams params,
  ) =>
      repository.createMercadoPagoSubscription(
        planId: params.planId,
        cardTokenId: params.cardTokenId,
      );
}
