enum PixAutomaticSubscriptionStatus {
  none,
  waitingAuthorization,
  active,
  paymentPending,
  blocked,
  rejected,
  cancelled,
  expired,
}

extension PixAutomaticSubscriptionStatusDb on PixAutomaticSubscriptionStatus {
  String get dbValue {
    switch (this) {
      case PixAutomaticSubscriptionStatus.none:
        return 'none';
      case PixAutomaticSubscriptionStatus.waitingAuthorization:
        return 'waiting_authorization';
      case PixAutomaticSubscriptionStatus.active:
        return 'active';
      case PixAutomaticSubscriptionStatus.paymentPending:
        return 'payment_pending';
      case PixAutomaticSubscriptionStatus.blocked:
        return 'blocked';
      case PixAutomaticSubscriptionStatus.rejected:
        return 'rejected';
      case PixAutomaticSubscriptionStatus.cancelled:
        return 'cancelled';
      case PixAutomaticSubscriptionStatus.expired:
        return 'expired';
    }
  }
}

PixAutomaticSubscriptionStatus pixAutomaticSubscriptionStatusFromDb(
  String? raw,
) {
  switch (raw) {
    case 'waiting_authorization':
      return PixAutomaticSubscriptionStatus.waitingAuthorization;
    case 'active':
      return PixAutomaticSubscriptionStatus.active;
    case 'payment_pending':
      return PixAutomaticSubscriptionStatus.paymentPending;
    case 'blocked':
      return PixAutomaticSubscriptionStatus.blocked;
    case 'rejected':
      return PixAutomaticSubscriptionStatus.rejected;
    case 'cancelled':
      return PixAutomaticSubscriptionStatus.cancelled;
    case 'expired':
      return PixAutomaticSubscriptionStatus.expired;
    case 'none':
    default:
      return PixAutomaticSubscriptionStatus.none;
  }
}

enum PaymentAccessStatus {
  allowed,
  warningPending,
  blocked,
}

extension PaymentAccessStatusDb on PaymentAccessStatus {
  String get dbValue {
    switch (this) {
      case PaymentAccessStatus.allowed:
        return 'allowed';
      case PaymentAccessStatus.warningPending:
        return 'warning_pending';
      case PaymentAccessStatus.blocked:
        return 'blocked';
    }
  }
}

PaymentAccessStatus paymentAccessStatusFromDb(String? raw) {
  switch (raw) {
    case 'allowed':
      return PaymentAccessStatus.allowed;
    case 'warning_pending':
      return PaymentAccessStatus.warningPending;
    case 'blocked':
    default:
      return PaymentAccessStatus.blocked;
  }
}
