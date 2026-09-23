import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/subscription_repository.dart';
import '../entities/subscription_status.dart';

class CancelSubscriptionUseCase {
  final SubscriptionRepository repository;

  const CancelSubscriptionUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String subscriptionId,
    String? reason,
    SubscriptionProvider provider = SubscriptionProvider.manual,
  }) {
    if (provider == SubscriptionProvider.manual) {
      return repository.cancelSubscription(
        subscriptionId: subscriptionId,
        reason: reason,
      );
    }
    return repository.cancelSubscription(
      subscriptionId: subscriptionId,
      reason: reason,
      provider: provider,
    );
  }
}
