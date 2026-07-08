import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/subscription_repository.dart';

class CancelSubscriptionUseCase {
  final SubscriptionRepository repository;

  const CancelSubscriptionUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String subscriptionId,
    String? reason,
  }) {
    return repository.cancelSubscription(
      subscriptionId: subscriptionId,
      reason: reason,
    );
  }
}
