import '../entities/subscription_status.dart';

class SubscriptionAccessPolicy {
  final SubscriptionBillingStatus status;
  final PaymentAccessStatus accessStatus;
  final DateTime? currentPeriodEnd;
  final DateTime? now;

  const SubscriptionAccessPolicy({
    required this.status,
    required this.accessStatus,
    this.currentPeriodEnd,
    this.now,
  });

  bool get canAccessBenefits {
    if (status == SubscriptionBillingStatus.active) {
      return accessStatus == PaymentAccessStatus.allowed && _hasPaidPeriod;
    }

    if (status == SubscriptionBillingStatus.paymentPending) {
      return _hasPaidPeriod &&
          (accessStatus == PaymentAccessStatus.warningPending ||
              accessStatus == PaymentAccessStatus.allowed);
    }

    if (status == SubscriptionBillingStatus.cancelled) {
      return accessStatus == PaymentAccessStatus.allowed && _hasPaidPeriod;
    }

    return false;
  }

  bool get canUseQr => canAccessBenefits;

  bool get mustShowPendingWarning =>
      status == SubscriptionBillingStatus.paymentPending &&
      accessStatus == PaymentAccessStatus.warningPending;

  bool get mustShowRestoreAccount => !canAccessBenefits;

  bool get _hasPaidPeriod {
    final end = currentPeriodEnd;
    if (end == null) return false;
    final reference = now ?? DateTime.now();
    return end.isAfter(reference);
  }
}
