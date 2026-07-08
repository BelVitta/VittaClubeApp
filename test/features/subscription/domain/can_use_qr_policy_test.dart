import 'package:flutter_test/flutter_test.dart';
import 'package:vita_clube/features/subscription/domain/entities/subscription_status.dart';
import 'package:vita_clube/features/subscription/domain/services/subscription_access_policy.dart';

void main() {
  test('canUseQr is false when subscription cannot grant paid access', () {
    for (final status in [
      PixAutomaticSubscriptionStatus.blocked,
      PixAutomaticSubscriptionStatus.rejected,
      PixAutomaticSubscriptionStatus.expired,
    ]) {
      final policy = SubscriptionAccessPolicy(
        status: status,
        accessStatus: PaymentAccessStatus.blocked,
      );

      expect(policy.canUseQr, isFalse, reason: status.name);
    }
  });
}
