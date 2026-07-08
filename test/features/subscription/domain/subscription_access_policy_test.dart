import 'package:flutter_test/flutter_test.dart';
import 'package:vita_clube/features/subscription/domain/entities/subscription_status.dart';
import 'package:vita_clube/features/subscription/domain/services/subscription_access_policy.dart';

void main() {
  group('SubscriptionAccessPolicy', () {
    test('allows full access only for active subscription', () {
      const policy = SubscriptionAccessPolicy(
        status: PixAutomaticSubscriptionStatus.active,
        accessStatus: PaymentAccessStatus.allowed,
      );

      expect(policy.canAccessBenefits, isTrue);
      expect(policy.canUseQr, isTrue);
      expect(policy.mustShowRestoreAccount, isFalse);
    });

    test('keeps access during payment pending recovery with warning', () {
      const policy = SubscriptionAccessPolicy(
        status: PixAutomaticSubscriptionStatus.paymentPending,
        accessStatus: PaymentAccessStatus.warningPending,
      );

      expect(policy.canAccessBenefits, isTrue);
      expect(policy.canUseQr, isTrue);
      expect(policy.mustShowPendingWarning, isTrue);
      expect(policy.mustShowRestoreAccount, isFalse);
    });

    test('blocks access and QR for blocked, rejected, expired and waiting', () {
      for (final status in [
        PixAutomaticSubscriptionStatus.blocked,
        PixAutomaticSubscriptionStatus.rejected,
        PixAutomaticSubscriptionStatus.expired,
        PixAutomaticSubscriptionStatus.waitingAuthorization,
      ]) {
        final policy = SubscriptionAccessPolicy(
          status: status,
          accessStatus: PaymentAccessStatus.blocked,
        );

        expect(policy.canAccessBenefits, isFalse, reason: status.name);
        expect(policy.canUseQr, isFalse, reason: status.name);
      }
    });

    test('cancelled subscription is allowed only while paid period is valid',
        () {
      final now = DateTime(2026, 6, 2);
      final allowed = SubscriptionAccessPolicy(
        status: PixAutomaticSubscriptionStatus.cancelled,
        accessStatus: PaymentAccessStatus.allowed,
        currentPeriodEnd: DateTime(2026, 6, 10),
        now: now,
      );
      final expired = SubscriptionAccessPolicy(
        status: PixAutomaticSubscriptionStatus.cancelled,
        accessStatus: PaymentAccessStatus.allowed,
        currentPeriodEnd: DateTime(2026, 6, 1),
        now: now,
      );

      expect(allowed.canAccessBenefits, isTrue);
      expect(allowed.canUseQr, isTrue);
      expect(expired.canAccessBenefits, isFalse);
      expect(expired.canUseQr, isFalse);
    });
  });
}
