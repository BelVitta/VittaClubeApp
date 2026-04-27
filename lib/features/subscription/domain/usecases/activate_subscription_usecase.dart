import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/subscription_entity.dart';
import '../repositories/subscription_repository.dart';

class ActivateSubscriptionUseCase {
  final SubscriptionRepository repository;

  ActivateSubscriptionUseCase(this.repository);

  Future<Either<Failure, SubscriptionEntity>> call({
    required String planId,
    required PlanLevelDb level,
  }) {
    return repository.activate(planId: planId, planLevelDb: level.name);
  }
}

/// Helper tipado para forçar que o chamador envie um valor válido do enum
/// `plan_level_status` do banco.
enum PlanLevelDb {
  bronze,
  prata,
  ouro,
  diamante,
}
