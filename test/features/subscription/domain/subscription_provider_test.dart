import 'package:flutter_test/flutter_test.dart';
import 'package:vita_clube/features/home/domain/entities/plan_level.dart';
import 'package:vita_clube/features/subscription/domain/entities/subscription_entity.dart';
import 'package:vita_clube/features/subscription/domain/entities/subscription_status.dart';

void main() {
  test('maps every persisted recurring provider', () {
    expect(subscriptionProviderFromDb('mercado_pago'),
        SubscriptionProvider.mercadoPago);
    expect(subscriptionProviderFromDb('woovi'), SubscriptionProvider.woovi);
    expect(subscriptionProviderFromDb('infinitypay'),
        SubscriptionProvider.infinityPayLegacy);
    expect(subscriptionProviderFromDb(null), SubscriptionProvider.manual);
  });

  test('cancelled Mercado Pago subscription keeps access through paid period',
      () {
    final subscription = SubscriptionEntity(
      id: 'sub',
      userId: 'user',
      planId: 'plan',
      level: PlanLevel.bronze,
      activationDate: DateTime(2026, 9, 1),
      isCurrent: true,
      billingStatus: SubscriptionBillingStatus.cancelled,
      provider: SubscriptionProvider.mercadoPago,
      paymentAccessStatus: PaymentAccessStatus.allowed,
      currentPeriodEnd: DateTime.now().add(const Duration(days: 5)),
    );
    expect(subscription.canAccessBenefits, isTrue);
  });
}
