import 'package:flutter_test/flutter_test.dart';
import 'package:vita_clube/features/subscription/domain/services/billing_cycle_policy.dart';

void main() {
  group('BillingCyclePolicy', () {
    test('keeps same billing day when month has the day', () {
      final next = BillingCyclePolicy.nextBillingDate(
        currentCycleDate: DateTime(2026, 6, 15),
        billingDay: 15,
      );

      expect(next, DateTime(2026, 7, 15));
    });

    test('uses last day when target month does not have billing day', () {
      final next = BillingCyclePolicy.nextBillingDate(
        currentCycleDate: DateTime(2026, 1, 31),
        billingDay: 31,
      );

      expect(next, DateTime(2026, 2, 28));
    });

    test('handles leap year February', () {
      final next = BillingCyclePolicy.nextBillingDate(
        currentCycleDate: DateTime(2028, 1, 31),
        billingDay: 31,
      );

      expect(next, DateTime(2028, 2, 29));
    });

    test('calculates current period end as next billing date', () {
      final end = BillingCyclePolicy.currentPeriodEnd(
        paidAt: DateTime(2026, 6, 2, 10),
        billingDay: 2,
      );

      expect(end, DateTime(2026, 7, 2));
    });
  });
}
