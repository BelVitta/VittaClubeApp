import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/subscription_entity.dart';
import '../repositories/subscription_repository.dart';

class RefreshSubscriptionStatusUseCase {
  final SubscriptionRepository repository;

  const RefreshSubscriptionStatusUseCase(this.repository);

  Future<Either<Failure, SubscriptionEntity?>> call() {
    return repository.refreshSubscriptionStatus();
  }
}
