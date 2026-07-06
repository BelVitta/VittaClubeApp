import '../entities/subscription_entity.dart';

class CanAccessBenefitsUseCase {
  const CanAccessBenefitsUseCase();

  bool call(SubscriptionEntity? subscription) {
    return subscription?.canAccessBenefits ?? false;
  }
}
