import 'package:flutter_test/flutter_test.dart';
import 'package:vita_clube/features/subscription/domain/entities/subscription_status.dart';
import 'package:vita_clube/features/subscription/domain/services/subscription_access_policy.dart';

void main() {
  test('payment_pending keeps benefits and QR available with warning', () {
    const policy = SubscriptionAccessPolicy(
      status: PixAutomaticSubscriptionStatus.paymentPending,
      accessStatus: PaymentAccessStatus.warningPending,
    );

    expect(policy.canAccessBenefits, isTrue);
    expect(policy.canUseQr, isTrue);
    expect(policy.mustShowPendingWarning, isTrue);
    expect(policy.mustShowRestoreAccount, isFalse);
  });
}
