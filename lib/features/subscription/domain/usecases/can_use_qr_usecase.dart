import '../entities/subscription_entity.dart';

class CanUseQrUseCase {
  const CanUseQrUseCase();

  bool call(SubscriptionEntity? subscription) {
    return subscription?.canUseQr ?? false;
  }
}
