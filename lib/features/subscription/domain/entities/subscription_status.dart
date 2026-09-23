enum SubscriptionBillingStatus {
  none,
  waitingAuthorization,
  active,
  paymentPending,
  blocked,
  rejected,
  cancelled,
  expired,
}

extension SubscriptionBillingStatusDb on SubscriptionBillingStatus {
  String get dbValue {
    switch (this) {
      case SubscriptionBillingStatus.none:
        return 'none';
      case SubscriptionBillingStatus.waitingAuthorization:
        return 'waiting_authorization';
      case SubscriptionBillingStatus.active:
        return 'active';
      case SubscriptionBillingStatus.paymentPending:
        return 'payment_pending';
      case SubscriptionBillingStatus.blocked:
        return 'blocked';
      case SubscriptionBillingStatus.rejected:
        return 'rejected';
      case SubscriptionBillingStatus.cancelled:
        return 'cancelled';
      case SubscriptionBillingStatus.expired:
        return 'expired';
    }
  }
}

SubscriptionBillingStatus subscriptionBillingStatusFromDb(
  String? raw,
) {
  switch (raw) {
    case 'waiting_authorization':
      return SubscriptionBillingStatus.waitingAuthorization;
    case 'active':
      return SubscriptionBillingStatus.active;
    case 'payment_pending':
      return SubscriptionBillingStatus.paymentPending;
    case 'blocked':
      return SubscriptionBillingStatus.blocked;
    case 'rejected':
      return SubscriptionBillingStatus.rejected;
    case 'cancelled':
      return SubscriptionBillingStatus.cancelled;
    case 'expired':
      return SubscriptionBillingStatus.expired;
    case 'none':
    default:
      return SubscriptionBillingStatus.none;
  }
}

/// Provedor externo responsável pela recorrência. O valor legado continua
/// explícito para permitir rollout sem reativar a rota da InfinitePay.
enum SubscriptionProvider { mercadoPago, woovi, infinityPayLegacy, manual }

extension SubscriptionProviderDb on SubscriptionProvider {
  String get dbValue => switch (this) {
        SubscriptionProvider.mercadoPago => 'mercado_pago',
        SubscriptionProvider.woovi => 'woovi',
        SubscriptionProvider.infinityPayLegacy => 'infinitypay_legacy',
        SubscriptionProvider.manual => 'manual',
      };
}

SubscriptionProvider subscriptionProviderFromDb(String? raw) => switch (raw) {
      'mercado_pago' => SubscriptionProvider.mercadoPago,
      'woovi' => SubscriptionProvider.woovi,
      'infinitypay_legacy' ||
      'infinitypay' =>
        SubscriptionProvider.infinityPayLegacy,
      _ => SubscriptionProvider.manual,
    };

@Deprecated('Use SubscriptionBillingStatus. Mantido para compatibilidade.')
typedef PixAutomaticSubscriptionStatus = SubscriptionBillingStatus;

@Deprecated('Use subscriptionBillingStatusFromDb.')
SubscriptionBillingStatus pixAutomaticSubscriptionStatusFromDb(String? raw) =>
    subscriptionBillingStatusFromDb(raw);

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
