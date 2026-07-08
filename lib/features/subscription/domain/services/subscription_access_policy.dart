import '../entities/subscription_status.dart';

class SubscriptionAccessPolicy {
  final PixAutomaticSubscriptionStatus status;
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
    if (status == PixAutomaticSubscriptionStatus.active) {
      return accessStatus == PaymentAccessStatus.allowed;
    }

    if (status == PixAutomaticSubscriptionStatus.paymentPending) {
      return accessStatus == PaymentAccessStatus.warningPending ||
          accessStatus == PaymentAccessStatus.allowed;
    }

    if (status == PixAutomaticSubscriptionStatus.cancelled) {
      return _hasPaidPeriod;
    }

    return false;
  }

  bool get canUseQr => canAccessBenefits;

  bool get mustShowPendingWarning =>
      status == PixAutomaticSubscriptionStatus.paymentPending &&
      accessStatus == PaymentAccessStatus.warningPending;

  bool get mustShowRestoreAccount => !canAccessBenefits;

  bool get _hasPaidPeriod {
    final end = currentPeriodEnd;
    if (end == null) return false;
    final reference = now ?? DateTime.now();
    return end.isAfter(reference) || _sameDate(end, reference);
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
